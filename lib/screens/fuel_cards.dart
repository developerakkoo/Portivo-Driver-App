import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/fuel_service.dart';

class FuelCardsScreen extends StatefulWidget {
  const FuelCardsScreen({super.key});

  @override
  State<FuelCardsScreen> createState() => _FuelCardsScreenState();
}

class _FuelCardsScreenState extends State<FuelCardsScreen> {
  final FuelService _fuelService = FuelService();
  Map<String, dynamic>? _assignedCard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedCard();
  }

  Future<void> _loadAssignedCard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final card = await _fuelService.getAssignedFuelCard();
      if (mounted) {
        setState(() {
          _assignedCard = card;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _maskedCardNumber(dynamic cardNumber) {
    final cn = cardNumber?.toString() ?? '';
    return '**** ${cn.length >= 4 ? cn.substring(cn.length - 4) : '****'}';
  }

  void _navigateToGenerateQR() {
    Navigator.of(context).pushNamed('/fuel-qr');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fuel Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAssignedCard,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _loadAssignedCard,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _assignedCard == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_outlined,
                                size: 64.0,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No fuel card assigned',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Ask your transporter to assign a fuel card to you.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAssignedCard,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fuel Card',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Text(
                                      _maskedCardNumber(_assignedCard!['cardNumber']),
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Text(
                                      'Balance: ₹${(num.tryParse('${_assignedCard!['balance'] ?? 0}') ?? 0).toStringAsFixed(2)}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              ElevatedButton.icon(
                                onPressed: _navigateToGenerateQR,
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Generate Fuel QR'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 24.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}

