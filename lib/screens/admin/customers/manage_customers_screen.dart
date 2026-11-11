import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/services/customer_service.dart';
import 'package:food_fight/providers/customer_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_scaffold.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:food_fight/core/localization/app_language.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  (String?, String?)? _lastScope;
  bool _scopePending = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().currentUser;
    final scope = (user?.id, user?.branchId);
    if (_lastScope != scope) {
      _lastScope = scope;
      _scopePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastScope == scope) {
          _scopePending = false;
          context.read<CustomerProvider>().loadCustomers(
                branchId: user?.branchId,
                scopeChanged: true,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCustomerDetail(UserModel customer) {
    final pageContext = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);
    final actor = context.read<AuthProvider>().currentUser;
    final platform = actor?.isSuperAdmin == true;
    final branchId = platform ? null : actor?.branchId;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: CustomerService.getCustomerStats(customer.id, branchId: branchId),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {'totalOrders': 0, 'totalSpent': 0.0};
            final totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;
            final totalSpent = (stats['totalSpent'] as num?)?.toDouble() ?? 0.0;
            final numbers = MaterialLocalizations.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Text(
                              customer.email,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.start,
                              style: TextStyle(color: textMuted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customer.phone.isNotEmpty)
                              Text(
                                customer.phone,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(color: textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: customer.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: customer.isActive ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          context.tr(customer.isActive ? 'Active' : 'Blocked'),
                          style: TextStyle(
                            color: customer.isActive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('Total Orders'), style: TextStyle(color: textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                numbers.formatDecimal(totalOrders),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr(platform ? 'Lifetime Spent' : 'Spent at this branch'),
                                  style: TextStyle(color: textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                "${context.tr('Rs.')} ${numbers.formatDecimal(totalSpent.round())}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customer.isActive ? AppColors.error : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(customer.isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                      label: Text(
                        context.tr(platform
                            ? (customer.isActive ? 'Block customer account' : 'Unblock customer account')
                            : (customer.isActive ? 'Block at this branch' : 'Unblock at this branch')),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = pageContext.read<CustomerProvider>();
                        final updated = await provider.toggleCustomerStatus(
                            customer.id, customer.isActive);
                        if (!updated && pageContext.mounted) {
                          AppSnackbar.showError(pageContext,
                              pageContext.tr('Unable to update customer access.'));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    return AdminScaffold(
      currentRoute: '/admin/customers',
      backgroundColor: AdminTheme.getBackground(context),
      appBar: AppBar(
        title: Text(context.tr('Customer Directory'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: context.tr('Refresh'),
            onPressed: () => context.read<CustomerProvider>().loadCustomers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customers = _scopePending ? const <UserModel>[] : provider.customers;
          return ResponsiveContainer.content(
            maxWidth: 1200,
            child: Column(
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => provider.setSearch(val),
                          decoration: InputDecoration(
                            hintText: context.tr('Search by customer name, email or phone...'),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      provider.setSearch('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: cardBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Customers List
                Expanded(
                  child: _scopePending || (provider.isLoading && customers.isEmpty)
                      ? LoadingIndicator(message: context.tr('Loading customer accounts...'))
                      : provider.errorMessage != null && customers.isEmpty
                          ? ErrorView(
                              message: context.tr(provider.errorMessage!),
                              onRetry: () => provider.loadCustomers(),
                            )
                          : customers.isEmpty
                              ? EmptyStateView(
                                  icon: Icons.people_outline_rounded,
                                  title: context.tr('No Customers Found'),
                                  description: context.tr(_searchCtrl.text.isNotEmpty
                                      ? 'No customer matched your search query.'
                                      : 'Registered customers will appear here.'),
                                )
                              : RefreshIndicator(
                                  onRefresh: provider.loadCustomers,
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: customers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final customer = customers[index];

                                      return Material(
                                        color: cardBg,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          side: BorderSide(
                                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                            child: Text(
                                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AdminTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            customer.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: textDark,
                                            ),
                                          ),
                                          subtitle: Text(
                                            customer.phone.isNotEmpty ? '${customer.email} • ${customer.phone}' : customer.email,
                                            textDirection: TextDirection.ltr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: textMuted, fontSize: 12.5),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: customer.isActive
                                                      ? AppColors.success.withValues(alpha: 0.1)
                                                      : AppColors.error.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  context.tr(customer.isActive ? 'Active' : 'Blocked'),
                                                  style: TextStyle(
                                                    color: customer.isActive ? AppColors.success : AppColors.error,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                            ],
                                          ),
                                          onTap: () => _showCustomerDetail(customer),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
