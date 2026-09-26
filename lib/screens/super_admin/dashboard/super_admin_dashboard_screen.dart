import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/widgets/super_admin/super_admin_drawer.dart';
import 'package:food_fight/widgets/admin/stat_card.dart';
import 'package:food_fight/providers/super_admin_provider.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/error_view.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textDark = SuperAdminTheme.getTextDark(context);

    final provider = context.watch<SuperAdminProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        final shouldSwitch = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Super Admin HQ?'),
            content: const Text('Do you want to return to the Customer Storefront?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SuperAdminTheme.primary),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Go to Storefront'),
              ),
            ],
          ),
        );
        if (shouldSwitch == true && context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      },
      child: Scaffold(
        backgroundColor: SuperAdminTheme.getBackground(context),
        drawer: const SuperAdminDrawer(currentRoute: '/super-admin/dashboard'),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: SuperAdminTheme.accentGold, size: 20),
            SizedBox(width: 8),
            Text(
              'Super Admin HQ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: SuperAdminTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => context.read<SuperAdminProvider>().loadMetrics(),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Restaurant Admin Panel',
            onPressed: () => Navigator.of(context).pushNamed('/admin/dashboard'),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.totalOrders == 0) {
            return const LoadingIndicator(message: 'Compiling platform-wide intelligence...');
          }

          if (provider.errorMessage != null && provider.totalOrders == 0) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.loadMetrics(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMetrics(),
            child: ResponsiveContainer.content(
              maxWidth: 1200,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            SuperAdminTheme.primary,
                            Color(0xFF230833),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: SuperAdminTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: SuperAdminTheme.accentGold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: SuperAdminTheme.accentGold, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Global System Operational ⚡',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Platform Revenue: Rs. ${provider.platformRevenue.toStringAsFixed(0)} • Store Open',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // User Accounts & Fleet Grid
                    Text(
                      'Platform Accounts & Fleet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;
                        final crossAxisCount = isWide ? 4 : 2;

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisExtent: 125,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          children: [
                            StatCard(
                              title: 'Admin Accounts',
                              value: '${provider.totalAdmins}',
                              icon: Icons.admin_panel_settings_rounded,
                              color: SuperAdminTheme.primary,
                              subtitle: 'Active Managers',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                            ),
                            StatCard(
                              title: 'Kitchen Staff',
                              value: '${provider.totalStaff}',
                              icon: Icons.soup_kitchen_rounded,
                              color: Colors.indigo.shade600,
                              subtitle: 'Operational Crew',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                            ),
                            StatCard(
                              title: 'Delivery Riders',
                              value: '${provider.totalRiders}',
                              icon: Icons.two_wheeler_rounded,
                              color: Colors.teal.shade600,
                              subtitle: 'Courier Fleet',
                              onTap: () => Navigator.of(context).pushNamed('/admin/delivery-areas'),
                            ),
                            StatCard(
                              title: 'Customers',
                              value: '${provider.totalCustomers}',
                              icon: Icons.people_alt_rounded,
                              color: Colors.purple.shade600,
                              subtitle: 'Registered Foodies',
                              onTap: () => Navigator.of(context).pushNamed('/admin/customers'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Platform Order Volume Grid
                    Text(
                      'Platform Order Lifecycle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;
                        final crossAxisCount = isWide ? 4 : 2;

                        return GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisExtent: 125,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          children: [
                            StatCard(
                              title: 'Total Orders',
                              value: '${provider.totalOrders}',
                              icon: Icons.receipt_long_rounded,
                              color: Colors.blue.shade700,
                              subtitle: 'Lifetime Volume',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Delivered Orders',
                              value: '${provider.completedOrders}',
                              icon: Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                              subtitle: 'Successful Dispatches',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Cancelled Orders',
                              value: '${provider.cancelledOrders}',
                              icon: Icons.cancel_rounded,
                              color: Colors.red.shade700,
                              subtitle: 'Refunded / Aborted',
                              onTap: () => Navigator.of(context).pushNamed('/admin/orders'),
                            ),
                            StatCard(
                              title: 'Restaurants',
                              value: '${provider.totalRestaurants}',
                              icon: Icons.store_rounded,
                              color: SuperAdminTheme.accentGold,
                              subtitle: 'Food Fight HQ Branch',
                              onTap: () => Navigator.of(context).pushNamed('/super-admin/settings'),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Management Actions
                    Text(
                      'Super Admin Quick Controls',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Manage Admins',
                            icon: Icons.manage_accounts_rounded,
                            color: SuperAdminTheme.primary,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/admins'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'System Settings',
                            icon: Icons.tune_rounded,
                            color: Colors.indigo.shade600,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/settings'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Audit Logs',
                            icon: Icons.policy_rounded,
                            color: Colors.teal.shade700,
                            onTap: () => Navigator.of(context).pushNamed('/super-admin/audit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            context: context,
                            title: 'Branch Portal',
                            icon: Icons.dashboard_customize_rounded,
                            color: Colors.amber.shade800,
                            onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildActionBtn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = SuperAdminTheme.getCardBg(context);
    final textDark = SuperAdminTheme.getTextDark(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
