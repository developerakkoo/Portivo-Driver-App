import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;
  bool _isLoading = false;

  final Map<String, String> _languages = {
    'English': 'English',
    'Hindi': 'हिंदी',
    'Marathi': 'मराठी',
  };

  void _handleContinue() {
    if (_selectedLanguage != null) {
      setState(() {
        _isLoading = true;
      });
      // TODO: Save language preference
      // Simulate loading
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // TODO: Navigate based on access status
          // For now, navigate to access pending screen
          Navigator.of(context).pushReplacementNamed('/access-pending');
          // Uncomment below when access is granted:
          // Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60.0),

              // Header Section
              _buildHeader(textTheme),

              const SizedBox(height: 48.0),

              // Language Options
              _buildLanguageOptions(textTheme),

              const SizedBox(height: 32.0),

              // Continue Button
              _buildContinueButton(theme),

              const SizedBox(height: 24.0),
            ],
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
          'Select Language',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12.0),

        // Subtitle
        Text(
          'Choose your preferred language',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageOptions(TextTheme textTheme) {
    return Column(
      children: _languages.entries.map((entry) {
        final isSelected = _selectedLanguage == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedLanguage = entry.key;
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.offWhite : AppColors.background,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.dividerGrey,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 24.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(ThemeData theme) {
    final canContinue = _selectedLanguage != null && !_isLoading;

    return SizedBox(
      height: 52.0,
      child: ElevatedButton(
        onPressed: canContinue ? _handleContinue : null,
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
                'Continue',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

