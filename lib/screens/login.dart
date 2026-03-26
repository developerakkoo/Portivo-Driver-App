import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mobile = _mobileController.text.trim();

      final success = await authProvider.loginWithOTP(mobile);

      if (!mounted) return;

      if (success) {
        final user = authProvider.user;
        if (user != null) {
          // Navigate based on driver status
          if (user.status == AppConstants.driverStatusPending) {
            Navigator.of(context).pushReplacementNamed('/access-pending');
          } else if (user.status == AppConstants.driverStatusBlocked) {
            setState(() {
              _errorMessage = 'Your account has been blocked. Please contact support.';
            });
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        // Handle error
        final error = authProvider.error;
        if (error != null) {
          String displayError = error;
          
          // Parse DioException for better error messages
          if (error.contains('DioException')) {
            if (error.contains('404')) {
              displayError = 'Driver not found. Please contact your transporter.';
            } else if (error.contains('403')) {
              displayError = 'Your account has been blocked. Please contact support.';
            } else if (error.contains('Connection')) {
              displayError = 'Network error. Please check your internet connection.';
            } else {
              displayError = 'Login failed. Please try again.';
            }
          }
          
          setState(() {
            _errorMessage = displayError;
          });
        }
      }
    }
  }

  bool get _canSignIn {
    final authProvider = Provider.of<AuthProvider>(context);
    return _mobileController.text.isNotEmpty && !authProvider.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60.0),

                // Header Section
                _buildHeader(textTheme),

                const SizedBox(height: 48.0),

                // Form Section
                _buildMobileField(textTheme),
                const SizedBox(height: 32.0),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20.0),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],

                // Primary Action
                _buildSignInButton(theme),

                const SizedBox(height: 24.0),

                // Footer
                _buildFooter(textTheme),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Heading
        Text(
          AppLocalizations.of(context)!.welcomeToPorttivoDriver,
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12.0),

        // Subtitle
        Text(
          AppLocalizations.of(context)!.pleaseEnterMobileNumber,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMobileField(TextTheme textTheme) {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignIn(),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.mobileNumber,
        hintText: AppLocalizations.of(context)!.enterMobileNumber,
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final localizations = AppLocalizations.of(context)!;
        if (value == null || value.isEmpty) {
          return localizations.pleaseEnterMobileNumberValidation;
        }
        // Remove any non-digit characters for validation
        final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length != 10) {
          return localizations.validMobileNumberValidation;
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton(ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SizedBox(
          height: 52.0,
          child: ElevatedButton(
            onPressed: _canSignIn ? _handleSignIn : null,
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20.0,
                    width: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.background,
                      ),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.signIn,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

