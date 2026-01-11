import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              _buildProfileHeader(textTheme),
              const SizedBox(height: 32.0),

              // Profile Info
              _buildProfileInfo(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(TextTheme textTheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.0,
          backgroundColor: AppColors.offWhite,
          child: Icon(
            Icons.person,
            size: 50.0,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Driver Name',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Driver ID: DRV-001',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(TextTheme textTheme) {
    return Column(
      children: [
        _buildInfoItem(
          icon: Icons.phone_outlined,
          label: 'Mobile Number',
          value: '+1 234 567 8900',
          textTheme: textTheme,
        ),
        const Divider(),
        _buildInfoItem(
          icon: Icons.email_outlined,
          label: 'Email',
          value: 'driver@example.com',
          textTheme: textTheme,
        ),
        const Divider(),
        _buildInfoItem(
          icon: Icons.badge_outlined,
          label: 'License Number',
          value: 'DL-123456',
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24.0,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

