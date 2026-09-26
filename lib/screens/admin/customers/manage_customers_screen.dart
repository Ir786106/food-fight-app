import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/providers/customer_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCustomerDetail(UserModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: context.read<CustomerProvider>().getCustomerStats(customer.id),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {'totalOrders': 0, 'totalSpent': 0.0};
            final totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;
            final totalSpent = (stats['totalSpent'] as num?)?.toDouble() ?? 0.0;

            return Padding(
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
                              style: TextStyle(color: textMuted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customer.phone.isNotEmpty)
                              Text(
                                customer.phone,
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
                          color: customer.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: customer.isActive ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          customer.isActive ? 'Active' : 'Blocked',
                          style: TextStyle(
                            color: customer.isActive ? Colors.green : Colors.red,
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
                              Text('Total Orders', style: TextStyle(color: textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '$totalOrders',
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
                              Text('Lifetime Spent', style: TextStyle(color: textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${totalSpent.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
                        backgroundColor: customer.isActive ? Colors.red.shade700 : Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(customer.isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                      label: Text(
                        customer.isActive ? 'Block Customer Account' : 'Reactivate Account',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<CustomerProvider>().toggleCustomerStatus(customer.id, customer.isActive);
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

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/customers'),
      appBar: AppBar(
        title: const Text('Customer Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
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
                            hintText: 'Search by customer name, email or phone...',
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
                  child: provider.isLoading && provider.customers.isEmpty
                      ? const LoadingIndicator(message: 'Loading customer accounts...')
                      : provider.errorMessage != null && provider.customers.isEmpty
                          ? ErrorView(
                              message: provider.errorMessage!,
                              onRetry: () => provider.watchCustomers(),
                            )
                          : provider.customers.isEmpty
                              ? EmptyStateView(
                                  icon: Icons.people_outline_rounded,
                                  title: 'No Customers Found',
                                  description: _searchCtrl.text.isNotEmpty
                                      ? 'No customer matched your search query.'
                                      : 'Registered customers will appear here.',
                                )
                              : RefreshIndicator(
                                  onRefresh: () async => provider.watchCustomers(),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: provider.customers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final customer = provider.customers[index];

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
                                                      ? Colors.green.withValues(alpha: 0.1)
                                                      : Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  customer.isActive ? 'Active' : 'Blocked',
                                                  style: TextStyle(
                                                    color: customer.isActive ? Colors.green : Colors.red,
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
