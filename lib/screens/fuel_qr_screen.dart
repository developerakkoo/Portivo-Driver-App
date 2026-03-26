import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';
import '../services/fuel_service.dart';

class FuelQRScreen extends StatefulWidget {
  const FuelQRScreen({super.key});

  @override
  State<FuelQRScreen> createState() => _FuelQRScreenState();
}

class _FuelQRScreenState extends State<FuelQRScreen> {
  final FuelService _fuelService = FuelService();
  final _vehicleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;
  bool _isConfirming = false;
  String? _error;
  String? _qrCodeImage;
  String? _qrCode;
  Map<String, dynamic>? _transaction;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _vehicleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      setState(() => _error = 'Failed to get location: $e');
    }
  }

  Future<void> _generateQR() async {
    final vehicle = _vehicleController.text.trim().toUpperCase();
    final amount = double.tryParse(_amountController.text.trim());

    if (vehicle.isEmpty) {
      setState(() => _error = 'Enter vehicle number');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter valid amount');
      return;
    }

    await _getLocation();
    if (_lat == null || _lng == null) {
      setState(() => _error = _error ?? 'Location required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _qrCodeImage = null;
      _qrCode = null;
      _transaction = null;
    });

    try {
      final data = await _fuelService.generateQR(
        vehicleNumber: vehicle,
        amount: amount,
        latitude: _lat!,
        longitude: _lng!,
      );

      if (data != null && mounted) {
        setState(() {
          _qrCodeImage = data['qrCodeImage']?.toString();
          _qrCode = data['qrCode']?.toString();
          _transaction = data['transaction'] is Map
              ? Map<String, dynamic>.from(data['transaction'])
              : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to generate QR';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmTransaction() async {
    if (_transaction == null || _qrCode == null) return;

    final transactionId = _transaction!['transactionId'] ?? _transaction!['_id'];
    final amount = (_transaction!['amount'] ?? 0).toDouble();

    if (transactionId == null) return;

    setState(() {
      _isConfirming = true;
      _error = null;
    });

    try {
      final data = await _fuelService.confirmTransaction(
        transactionId: transactionId.toString(),
        amount: amount,
      );

      if (data != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction confirmed. Show QR to pump staff.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = 'Failed to confirm');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Generate Fuel QR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              if (_qrCodeImage == null) ...[
                TextField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number',
                    hintText: 'e.g. KA01AA0001',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'e.g. 500',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateQR,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate QR'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_qrCodeImage != null)
                        Image.memory(
                          base64Decode(
                            _qrCodeImage!.contains(',')
                                ? _qrCodeImage!.split(',').last
                                : _qrCodeImage!,
                          ),
                          height: 200,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Show this QR to pump staff',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: _isConfirming ? null : _confirmTransaction,
                        child: _isConfirming
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm Transaction'),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _qrCodeImage = null;
                            _qrCode = null;
                            _transaction = null;
                          });
                        },
                        child: const Text('Generate New QR'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
