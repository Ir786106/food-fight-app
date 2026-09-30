import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/order_provider.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? initialOrderId;

  const CustomerChatScreen({super.key, this.initialOrderId});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  OrderModel? _linkedOrder;

  static const List<String> _quickReplies = [
    'Where is my order?',
    'Change address',
    'Wrong/missing item',
    'Cancel order',
    'Payment issue',
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final isComp = _textCtrl.text.trim().isNotEmpty;
      if (isComp != _isComposing) {
        setState(() => _isComposing = isComp);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatSession();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initChatSession() async {
    final auth = context.read<AuthProvider>();
    final branchProv = context.read<BranchProvider>();
    final orderProv = context.read<OrderProvider>();
    final chatProv = context.read<ChatProvider>();

    final user = auth.currentUser;
    if (user == null) return;

    // Determine target orderId if passed via widget or route settings
    String? orderId = widget.initialOrderId;
    if (orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        orderId = args;
      } else if (args is Map && args['orderId'] != null) {
        orderId = args['orderId'].toString();
      }
    }

    String? orderNumber;
    String targetBranchId = branchProv.selectedBranch?.id ?? 'branch_1';

    if (orderId != null && orderId.isNotEmpty) {
      final foundOrder = orderProv.getOrderById(orderId);
      if (foundOrder != null) {
        setState(() => _linkedOrder = foundOrder);
        orderNumber = foundOrder.orderNumber;
        if (foundOrder.branchId != null && foundOrder.branchId!.isNotEmpty) {
          targetBranchId = foundOrder.branchId!;
        }
      } else {
        // Try fetching it asynchronously
        orderProv.fetchOrderById(orderId).then((ord) {
          if (ord != null && mounted) {
            setState(() => _linkedOrder = ord);
          }
        });
      }
    }

    await chatProv.openChatChannel(
      customerId: user.id,
      customerName: user.name.isNotEmpty ? user.name : 'Customer',
      customerPhone: user.phone,
      branchId: targetBranchId,
      orderId: orderId,
      orderNumber: orderNumber,
      userRole: 'customer',
    );
  }

  Future<void> _handleSendMessage({String? customText}) async {
    final text = customText ?? _textCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    if (customText == null) {
      _textCtrl.clear();
    }

    final success = await chatProv.sendMessage(
      senderId: user.id,
      senderRole: 'customer',
      senderName: user.name.isNotEmpty ? user.name : 'Customer',
      text: text,
    );

    if (success && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleAttachImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await chatProv.sendImage(
      image: image,
      senderId: user.id,
      senderRole: 'customer',
      senderName: user.name.isNotEmpty ? user.name : 'Customer',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chatProv = context.watch<ChatProvider>();
    final activeChat = chatProv.activeChat;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandYellow, width: 1.5),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.brandMaroon,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Food Fight Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMaroon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        activeChat?.status == 'resolved' ? 'Resolved' : 'Online • Replies in minutes',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (activeChat != null && activeChat.status != 'resolved')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'resolve') {
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  chatProv.updateStatus(
                    'resolved',
                    actorName: user?.name ?? 'Customer',
                    actorEmail: user?.email ?? '',
                    actorRole: 'customer',
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 10),
                      Text('Mark issue resolved'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Linked Order Context Card
            if (_linkedOrder != null) _buildOrderContextCard(_linkedOrder!),

            // 2. Resolved Banner
            if (activeChat != null && activeChat.status == 'resolved')
              _buildResolvedBanner(activeChat),

            // 3. Error Banner if sending failed
            if (chatProv.sendErrorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.errorSoft,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProv.sendErrorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleSendMessage(),
                      child: const Text('Retry', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // 4. Message List
            Expanded(
              child: chatProv.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : chatProv.activeMessages.isEmpty
                      ? _buildEmptyChatView()
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: chatProv.activeMessages.length,
                          itemBuilder: (context, index) {
                            final msg = chatProv.activeMessages[index];
                            final isLast = index == 0;
                            final showDate = _shouldShowDateSeparator(chatProv.activeMessages, index);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDate) _buildDateSeparator(msg.createdAt),
                                _buildMessageBubble(msg, isLast),
                              ],
                            );
                          },
                        ),
            ),

            // 5. Quick-Reply Chips (Visible when chat is open)
            if (activeChat?.status != 'resolved') _buildQuickRepliesBar(),

            // 6. Composer Input Bar
            _buildInputBar(activeChat),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderContextCard(OrderModel order) {
    final statusInfo = AppStatusColors.of(context).forStatus(order.status);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusInfo.softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusInfo.icon, color: statusInfo.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.brandMaroon,
                      ),
                    ),
                    Text(
                      'Rs. ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.brandMaroon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusInfo.softColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(
                          color: statusInfo.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/order-tracking',
                          arguments: order.id,
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Track Order',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandMaroon,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.brandMaroon),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedBanner(dynamic activeChat) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This inquiry has been marked as resolved.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandMaroon,
              side: const BorderSide(color: AppColors.brandMaroon, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              final chatProv = context.read<ChatProvider>();
              final user = auth.currentUser;
              chatProv.updateStatus(
                'open',
                actorName: user?.name ?? 'Customer',
                actorEmail: user?.email ?? '',
                actorRole: 'customer',
              );
            },
            child: const Text('Reopen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.yellowSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.brandMaroon,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'How can we help you today?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.brandMaroon,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our team is ready to help with orders, deliveries, branch info or feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickReplies.map((reply) {
                return ActionChip(
                  label: Text(reply, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandMaroon)),
                  backgroundColor: AppColors.yellowTint,
                  side: const BorderSide(color: AppColors.brandYellow, width: 1),
                  onPressed: () => _handleSendMessage(customText: reply),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brandMaroon,
              ),
            ),
            backgroundColor: AppColors.yellowSoft,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () => _handleSendMessage(customText: reply),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isLatest) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCustomer = msg.isCustomer;
    final timeStr = DateFormat('h:mm a').format(msg.createdAt);

    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isCustomer
              ? AppColors.brandYellow
              : (isDark ? AppColors.darkSurfaceElevated : AppColors.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCustomer ? 16 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 16),
          ),
          border: isCustomer
              ? null
              : Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCustomer)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg.senderName.isNotEmpty ? msg.senderName : 'Food Fight Support',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandMaroon,
                  ),
                ),
              ),

            // Image attachment if present
            if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    msg.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
              ),

            // Text content
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: isCustomer
                      ? AppColors.brandMaroon
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),

            const SizedBox(height: 4),

            // Timestamp + read receipt
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCustomer
                        ? AppColors.brandMaroon.withValues(alpha: 0.7)
                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  ),
                ),
                if (isCustomer) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: msg.readBy.length > 1
                        ? AppColors.brandMaroon
                        : AppColors.brandMaroon.withValues(alpha: 0.45),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dateStr = isToday ? 'Today' : DateFormat('MMM d, yyyy').format(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateStr,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(List<ChatMessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index].createdAt;
    final older = messages[index + 1].createdAt;
    return current.day != older.day || current.month != older.month || current.year != older.year;
  }

  Widget _buildInputBar(dynamic activeChat) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_camera_back_outlined, color: AppColors.brandMaroon, size: 24),
            tooltip: 'Attach Photo',
            onPressed: _handleAttachImage,
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontSize: 13.5,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isComposing ? AppColors.brandMaroon : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                size: 20,
                color: _isComposing ? AppColors.brandYellow : AppColors.textMuted,
              ),
              onPressed: _isComposing ? () => _handleSendMessage() : null,
            ),
          ),
        ],
      ),
    );
  }
}
