import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  // Placeholder data
  static const double availableBalance = 0.00;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.walletTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              _buildBalanceCard(context, textTheme),
              const SizedBox(height: 24.0),

              // Action Buttons
              _buildActionButtons(context, textTheme),
              const SizedBox(height: 32.0),

              // Recent Transactions
              _buildTransactionsSection(context, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.walletBalance,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.background.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '\$${availableBalance.toStringAsFixed(2)}',
            style: textTheme.headlineLarge?.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52.0,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement add money
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Add Money',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: SizedBox(
            height: 52.0,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement withdraw
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Withdraw',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.transactions,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16.0),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48.0,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16.0),
                Text(
                  AppLocalizations.of(context)!.noTransactions,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

