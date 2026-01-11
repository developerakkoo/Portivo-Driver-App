import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      // TODO: Implement actual sign-in logic
      // Simulate loading for demonstration
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pushReplacementNamed('/language-selection');
        }
      });
    }
  }

  bool get _canSignIn {
    return _mobileController.text.isNotEmpty && !_isLoading;
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
        // Logo
        Image.asset(
          'assets/logo.png',
          height: 80.0,
          width: 180.0,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(height: 80.0, width: 180.0);
          },
        ),
        const SizedBox(height: 32.0),

        // Heading
        Text(
          'Welcome to Porttivo Driver',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12.0),

        // Subtitle
        Text(
          'Please enter your mobile number to continue',
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
      decoration: const InputDecoration(
        labelText: 'Mobile Number',
        hintText: 'Enter your mobile number',
      ),
      onChanged: (_) => setState(() {}),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your mobile number';
        }
        if (value.length < 10) {
          return 'Please enter a valid mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton(ThemeData theme) {
    return SizedBox(
      height: 52.0,
      child: ElevatedButton(
        onPressed: _canSignIn ? _handleSignIn : null,
        child: _isLoading
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
                'Sign in',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
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

