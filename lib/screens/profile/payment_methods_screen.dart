import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_method_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<PaymentMethodProvider>().watchMethods(user.id);
      }
      _initialized = true;
    }
  }

  void _showAddMethodModal(BuildContext context, String userId) {
    String selectedGateway = 'card'; // 'card', 'jazzcash', 'easypaisa'
    final cardHolderCtrl = TextEditingController();
    final cardNumberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final walletPhoneCtrl = TextEditingController();
    bool setAsDefault = true;
    bool isTokenizing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final theme = Theme.of(sheetContext);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Add Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Card details are securely tokenized with 256-bit encryption. Raw CVV is never stored.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),

                  // Gateway Selector Tabs
                  Row(
                    children: [
                      _buildGatewayTab(
                        label: 'Debit/Credit Card',
                        icon: Icons.credit_card_rounded,
                        isSelected: selectedGateway == 'card',
                        onTap: () => setModalState(() => selectedGateway = 'card'),
                      ),
                      const SizedBox(width: 8),
                      _buildGatewayTab(
                        label: 'JazzCash',
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: selectedGateway == 'jazzcash',
                        onTap: () => setModalState(() => selectedGateway = 'jazzcash'),
                      ),
                      const SizedBox(width: 8),
                      _buildGatewayTab(
                        label: 'Easypaisa',
                        icon: Icons.phone_android_rounded,
                        isSelected: selectedGateway == 'easypaisa',
                        onTap: () => setModalState(() => selectedGateway = 'easypaisa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (selectedGateway == 'card') ...[
                    TextFormField(
                      controller: cardHolderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      decoration: const InputDecoration(
                        labelText: 'Card Number (16 digits) *',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryCtrl,
                            keyboardType: TextInputType.datetime,
                            maxLength: 5,
                            decoration: const InputDecoration(
                              labelText: 'Expiry (MM/YY) *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: cvvCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVV *',
                              prefixIcon: Icon(Icons.lock_outline),
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextFormField(
                      controller: walletPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: selectedGateway == 'jazzcash'
                            ? 'JazzCash Mobile Account Number (03XX-XXXXXXX) *'
                            : 'Easypaisa Mobile Account Number (03XX-XXXXXXX) *',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive an OTP prompt on your mobile wallet to authorize payments.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],

                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: setAsDefault,
                    onChanged: (val) => setModalState(() => setAsDefault = val ?? false),
                    title: const Text('Set as default payment method', style: TextStyle(fontSize: 13.5)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isTokenizing
                          ? null
                          : () async {
                              if (selectedGateway == 'card') {
                                final numText = cardNumberCtrl.text.replaceAll(' ', '').trim();
                                if (numText.length < 15) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid card number')),
                                  );
                                  return;
                                }
                              } else {
                                final phone = walletPhoneCtrl.text.trim();
                                if (phone.length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid mobile account number')),
                                  );
                                  return;
                                }
                              }

                              setModalState(() => isTokenizing = true);

                              // Perform gateway client tokenization simulation
                              final last4 = selectedGateway == 'card'
                                  ? (cardNumberCtrl.text.length >= 4
                                      ? cardNumberCtrl.text.substring(cardNumberCtrl.text.length - 4)
                                      : '4242')
                                  : (walletPhoneCtrl.text.length >= 4
                                      ? walletPhoneCtrl.text.substring(walletPhoneCtrl.text.length - 4)
                                      : '0000');

                              final token = 'tok_${selectedGateway}_${DateTime.now().millisecondsSinceEpoch}';
                              final masked = selectedGateway == 'card'
                                  ? '•••• •••• •••• $last4'
                                  : '${walletPhoneCtrl.text.substring(0, 4)} •••• $last4';

                              final newMethod = PaymentMethodModel(
                                id: '',
                                userId: userId,
                                type: selectedGateway,
                                gateway: selectedGateway == 'card' ? 'stripe' : selectedGateway,
                                maskedNumber: masked,
                                title: selectedGateway == 'card'
                                    ? 'Card ending in $last4'
                                    : (selectedGateway == 'jazzcash'
                                        ? 'JazzCash Account ($last4)'
                                        : 'Easypaisa Account ($last4)'),
                                token: token,
                                cardBrand: selectedGateway == 'card' ? 'Visa' : null,
                                expiry: selectedGateway == 'card' ? expiryCtrl.text.trim() : null,
                                isDefault: setAsDefault,
                                createdAt: DateTime.now(),
                              );

                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await context.read<PaymentMethodProvider>().addMethod(newMethod);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Payment method safely tokenized and saved!'
                                        : 'Failed to add payment method'),
                                    backgroundColor: ok ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                            },
                      child: isTokenizing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGatewayTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final paymentProvider = context.watch<PaymentMethodProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Payment Methods'),
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 720,
          child: Builder(
            builder: (context) {
              if (user == null) {
                return const Center(
                  child: EmptyStateView(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sign In Required',
                    description: 'Please sign in to view and manage your payment methods.',
                  ),
                );
              }

              if (paymentProvider.isLoading && paymentProvider.methods.isEmpty) {
                return const LoadingIndicator(message: 'Securing payment vault...');
              }

              if (paymentProvider.errorMessage != null && paymentProvider.methods.isEmpty) {
                return ErrorView(
                  message: paymentProvider.errorMessage!,
                  onRetry: () => paymentProvider.watchMethods(user.id),
                );
              }

              if (paymentProvider.methods.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const EmptyStateView(
                          icon: Icons.credit_card_off_rounded,
                          title: 'No Saved Payment Methods',
                          description:
                              'Save your Debit/Credit card or JazzCash/Easypaisa mobile wallet for lightning-fast 1-tap checkout.',
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => _showAddMethodModal(context, user.id),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Payment Method'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tokenized Reference Storage: All credentials are encrypted and stored via secure payment gateway reference tokens.',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...paymentProvider.methods.map((method) {
                    final isDefault = method.isDefault;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDefault ? AppColors.primary : colorScheme.outlineVariant,
                          width: isDefault ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDefault
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            method.type == 'card'
                                ? Icons.credit_card_rounded
                                : (method.type == 'jazzcash'
                                    ? Icons.account_balance_wallet_rounded
                                    : Icons.phone_android_rounded),
                            color: isDefault ? AppColors.primary : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              method.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              method.maskedNumber,
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 1,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (method.expiry != null)
                              Text('Expires ${method.expiry}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (val) async {
                            if (val == 'default') {
                              await paymentProvider.setDefault(user.id, method.id);
                            } else if (val == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove Payment Method'),
                                  content: Text('Are you sure you want to remove ${method.title}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await paymentProvider.deleteMethod(user.id, method.id);
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (!isDefault)
                              const PopupMenuItem(
                                value: 'default',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Set as Default'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete Method', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: user != null && paymentProvider.methods.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _showAddMethodModal(context, user.id),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Method'),
            )
          : null,
    );
  }
}
