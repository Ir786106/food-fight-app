import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:food_fight/models/admin/audit_log_model.dart';
import 'package:food_fight/providers/audit_log_provider.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/super_admin/super_admin_drawer.dart';

/// Super Admin Audit & Activity Logs Screen
class SuperAdminAuditLogsScreen extends StatefulWidget {
  const SuperAdminAuditLogsScreen({super.key});

  @override
  State<SuperAdminAuditLogsScreen> createState() =>
      _SuperAdminAuditLogsScreenState();
}

class _SuperAdminAuditLogsScreenState extends State<SuperAdminAuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _entityTabs = [
    {'id': 'all', 'label': 'All Activities'},
    {'id': 'order', 'label': 'Orders'},
    {'id': 'admin', 'label': 'Admin / Accounts'},
    {'id': 'menu', 'label': 'Menu Items'},
    {'id': 'category', 'label': 'Categories'},
    {'id': 'coupon', 'label': 'Coupons'},
    {'id': 'system', 'label': 'System Settings'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m ${dt.day}, ${dt.year} • $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final auditProvider = context.watch<AuditLogProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = SuperAdminTheme.getTextDark(context);
    final textMuted = SuperAdminTheme.getTextMuted(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/super-admin/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: SuperAdminTheme.getBackground(context),
        drawer: const SuperAdminDrawer(currentRoute: '/super-admin/audit'),
        appBar: AppBar(
          backgroundColor: SuperAdminTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Audit & Activity Log',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'Platform-wide event monitoring & tracking',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh Logs',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => auditProvider.watchLogs(),
            ),
          ],
        ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: SuperAdminTheme.getCardBg(context),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => auditProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by action, actor, or description...',
                    hintStyle: TextStyle(fontSize: 13, color: textMuted),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              auditProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF22172C) : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Entity Filter Horizontal List
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _entityTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = _entityTabs[index];
                      final isSelected = auditProvider.entityFilter == tab['id'];

                      return FilterChip(
                        selected: isSelected,
                        label: Text(
                          tab['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : textDark.withValues(alpha: 0.8),
                          ),
                        ),
                        selectedColor: SuperAdminTheme.primary,
                        backgroundColor: isDark ? const Color(0xFF22172C) : Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? SuperAdminTheme.primary
                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                        ),
                        onSelected: (val) {
                          auditProvider.setEntityFilter(tab['id']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Log List Content
          Expanded(
            child: _buildLogContent(context, auditProvider),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLogContent(BuildContext context, AuditLogProvider provider) {
    if (provider.isLoading && provider.logs.isEmpty) {
      return const Center(
        child: LoadingIndicator(message: 'Loading platform audit trail...'),
      );
    }

    if (provider.errorMessage != null && provider.logs.isEmpty) {
      return Center(
        child: ErrorView(
          message: provider.errorMessage!,
          onRetry: () => provider.watchLogs(),
        ),
      );
    }

    if (provider.logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => provider.watchLogs(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyStateView(
              icon: Icons.history_toggle_off_rounded,
              title: 'No Activity Logs Recorded',
              description:
                  'There are no audit events matching your current filter criteria.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.watchLogs(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: provider.logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final log = provider.logs[index];
          return _buildAuditCard(context, log);
        },
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, AuditLogModel log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = SuperAdminTheme.getTextDark(context);
    final textMuted = SuperAdminTheme.getTextMuted(context);
    final cardBg = SuperAdminTheme.getCardBg(context);

    final entityConfig = _getEntityVisuals(log.targetEntity);
    final timeStr = _formatDate(log.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Entity Badge + Action + Timestamp
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entityConfig['color'].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    entityConfig['icon'] as IconData,
                    color: entityConfig['color'] as Color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: entityConfig['color'].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.targetEntity.toUpperCase(),
                              style: TextStyle(
                                color: entityConfig['color'] as Color,
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              log.action.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              log.description,
              style: TextStyle(
                fontSize: 13,
                color: textDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Footer: Actor pill + Target ID
            Row(
              children: [
                // Actor Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22172C) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${log.actorName} (${log.actorRole})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (log.targetId.isNotEmpty)
                  Text(
                    'ID: ${log.targetId.length > 8 ? '${log.targetId.substring(0, 8)}...' : log.targetId}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: textMuted,
                    ),
                  ),
              ],
            ),

            // Optional Metadata expansion if present
            if (log.metadata != null && log.metadata!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.metadata.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getEntityVisuals(String entity) {
    switch (entity.toLowerCase()) {
      case 'order':
        return {
          'icon': Icons.shopping_bag_rounded,
          'color': AppColors.primaryYellow,
        };
      case 'admin':
        return {
          'icon': Icons.admin_panel_settings_rounded,
          'color': SuperAdminTheme.primary,
        };
      case 'menu':
        return {
          'icon': Icons.restaurant_menu_rounded,
          'color': AppColors.accent,
        };
      case 'category':
        return {
          'icon': Icons.category_rounded,
          'color': AppColors.darkBrown,
        };
      case 'coupon':
        return {
          'icon': Icons.confirmation_number_rounded,
          'color': AppColors.primaryYellow,
        };
      case 'system':
        return {
          'icon': Icons.settings_rounded,
          'color': AppColors.darkBrown,
        };
      default:
        return {
          'icon': Icons.history_rounded,
          'color': AppColors.textSecondary,
        };
    }
  }
}
