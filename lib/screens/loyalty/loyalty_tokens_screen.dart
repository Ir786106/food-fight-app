import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/loading_indicator.dart';

class LoyaltyTokensScreen extends StatefulWidget {
  const LoyaltyTokensScreen({super.key});

  @override
  State<LoyaltyTokensScreen> createState() => _LoyaltyTokensScreenState();
}

class _LoyaltyTokensScreenState extends State<LoyaltyTokensScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<LoyaltyProvider>().watchAccount(user.id);
      }
    });
  }

  String _getTierName(int totalEarned) {
    if (totalEarned >= 2000) return 'FOODIE CHAMPION';
    if (totalEarned >= 1000) return 'GOLD GOURMET';
    if (totalEarned >= 400) return 'SILVER SNACKER';
    return 'BRONZE BITE';
  }

  Color _getTierColor(int totalEarned) {
    if (totalEarned >= 2000) return const Color(0xFFFFD504);
    if (totalEarned >= 1000) return const Color(0xFFFFB300);
    if (totalEarned >= 400) return const Color(0xFFB0BEC5);
    return const Color(0xFFCD7F32);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loyalty = context.watch<LoyaltyProvider>();
    final account = loyalty.account;
    final transactions = loyalty.transactions;

    final balance = loyalty.balance;
    final totalEarned = account?.totalEarned ?? balance;
    final tier = _getTierName(totalEarned);
    final tierColor = _getTierColor(totalEarned);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Loyalty Tokens', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loyalty.isLoading && account == null
          ? const Center(child: LoadingIndicator(message: 'Loading token balance...'))
          : RefreshIndicator(
              color: AppColors.brandYellow,
              backgroundColor: AppColors.brandMaroon,
              onRefresh: () async {
                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  context.read<LoyaltyProvider>().watchAccount(user.id);
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  // Balance & Tier Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF800020), Color(0xFF4A0012)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF800020).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded, color: tierColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    tier,
                                    style: TextStyle(
                                      color: tierColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandYellow.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🎁', style: TextStyle(fontSize: 20)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Available Tokens',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$balance',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandYellow,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tokens',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '≈ Rs ${(balance * loyalty.tokenValueInCurrency).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('Lifetime Earned', '$totalEarned'),
                            _buildStatItem('Lifetime Redeemed', '${account?.totalRedeemed ?? 0}'),
                            _buildStatItem(
                              'Value Rate',
                              '1 Token = Rs ${loyalty.tokenValueInCurrency.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // How it works card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.brandMaroon, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'How Loyalty Tokens Work',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRuleRow(
                          '🌟',
                          'Earn on Every Order',
                          'Get 1 token for every Rs ${loyalty.earnRateInCurrency} spent on food delivery.',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildRuleRow(
                          '💰',
                          'Instant Checkout Discount',
                          'Redeem tokens in Cart & Checkout (1 token = Rs ${loyalty.tokenValueInCurrency.toStringAsFixed(0)} discount).',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildRuleRow(
                          '🎉',
                          'Welcome Bonus',
                          'New members receive ${loyalty.welcomeBonusTokens} free tokens on first sign up.',
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transaction History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Token History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${transactions.length} events',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: const EmptyStateView(
                        icon: Icons.savings_outlined,
                        title: 'No Token Transactions Yet',
                        description: 'Place an order or sign up to earn Food Fight tokens!',
                      ),
                    )
                  else
                    ...transactions.map((tx) {
                      final isCredit = tx.type == 'credit' || tx.type == 'bonus' || tx.type == 'earn' || tx.type == 'refund';
                      final amountStr = isCredit ? '+${tx.amount}' : '-${tx.amount}';
                      final dateStr = DateFormat('MMM d, y • h:mm a').format(tx.createdAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isCredit
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : AppColors.brandMaroon.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isCredit ? Colors.green : AppColors.brandMaroon,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description.isNotEmpty
                                        ? tx.description
                                        : (isCredit ? 'Tokens Earned' : 'Tokens Redeemed'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              amountStr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isCredit ? Colors.green : AppColors.brandMaroon,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleRow(String emoji, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
