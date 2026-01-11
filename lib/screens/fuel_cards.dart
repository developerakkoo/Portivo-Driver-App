import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class FuelCardsScreen extends StatelessWidget {
  const FuelCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fuel Cards'),
      ),
      body: SafeArea(
        child: Center(
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
                  'No fuel cards',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Your fuel cards will appear here',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

