import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Porttivo Driver'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section
              _buildWelcomeSection(textTheme),
              const SizedBox(height: 32.0),

              // Quick Stats
              _buildQuickStats(textTheme),
              const SizedBox(height: 32.0),

              // Placeholder content
              Text(
                'Your dashboard content will appear here',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Ready to start your day?',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_shipping,
            value: '0',
            label: 'Active Trips',
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            value: '0',
            label: 'Completed',
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.dividerGrey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32.0, color: AppColors.primary),
          const SizedBox(height: 12.0),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

