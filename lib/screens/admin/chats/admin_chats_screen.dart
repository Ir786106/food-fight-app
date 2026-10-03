import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/admin/admin_collapsible_sidebar.dart';
import '../orders/order_detail_modal.dart';

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String? _selectedBranchFilter;
  ChatModel? _selectedChat;
  bool _isComposing = false;

  static const List<String> _cannedReplies = [
    'Your order is being prepared.',
    'Rider is on the way.',
    'Sorry for the inconvenience, we are checking.',
    'Please confirm your delivery address.',
    'Thank you for contacting Food Fight support!',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });

    _replyCtrl.addListener(() {
      final isComp = _replyCtrl.text.trim().isNotEmpty;
      if (isComp != _isComposing) {
        setState(() => _isComposing = isComp);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAdminChatStream();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _replyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initAdminChatStream() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final chatProv = context.read<ChatProvider>();

    if (user == null) return;

    final isSuper = user.isSuperAdmin || (user.branchId == null || user.branchId!.isEmpty || user.branchId == 'all');
    final branchId = _selectedBranchFilter ?? (user.branchId ?? '');

    chatProv.streamAdminChats(
      branchId,
      isSuperAdmin: isSuper && (_selectedBranchFilter == null || _selectedBranchFilter!.isEmpty),
    );
  }

  void _selectChat(ChatModel chat) {
    setState(() => _selectedChat = chat);

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final chatProv = context.read<ChatProvider>();

    chatProv.openExistingChat(
      chat,
      user?.id ?? '',
      user?.role ?? 'admin',
    );
  }

  Future<void> _handleAdminSend({String? customText}) async {
    final text = customText ?? _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final chatProv = context.read<ChatProvider>();
    if (user == null) return;

    if (customText == null) {
      _replyCtrl.clear();
    }

    final success = await chatProv.sendMessage(
      senderId: user.id,
      senderRole: user.isSuperAdmin ? 'super_admin' : 'admin',
      senderName: user.name.isNotEmpty ? user.name : 'Branch Admin',
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
    final user = auth.currentUser;
    final chatProv = context.read<ChatProvider>();
    if (user == null) return;

    await chatProv.sendImage(
      image: image,
      senderId: user.id,
      senderRole: user.isSuperAdmin ? 'super_admin' : 'admin',
      senderName: user.name.isNotEmpty ? user.name : 'Branch Admin',
    );
  }

  void _openOrderModal(String orderId) async {
    final orderProv = context.read<OrderProvider>();
    OrderModel? order = orderProv.getOrderById(orderId);
    order ??= await orderProv.fetchOrderById(orderId);

    if (order != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OrderDetailModal(order: order!),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details could not be found.')),
      );
    }
  }

  List<ChatModel> _filterChats(List<ChatModel> allChats) {
    var chats = allChats;

    // 1. Status Tab filter
    switch (_tabController.index) {
      case 0: // Open
        chats = chats.where((c) => c.status == 'open').toList();
        break;
      case 1: // Pending (waiting on customer or review)
        chats = chats.where((c) => c.status == 'pending').toList();
        break;
      case 2: // Resolved
        chats = chats.where((c) => c.status == 'resolved').toList();
        break;
      case 3: // All
      default:
        break;
    }

    // 2. Branch Filter (for Super Admin)
    if (_selectedBranchFilter != null && _selectedBranchFilter!.isNotEmpty) {
      chats = chats.where((c) => c.branchId == _selectedBranchFilter).toList();
    }

    // 3. Search query
    if (_searchQuery.isNotEmpty) {
      chats = chats.where((c) {
        final nameMatch = c.customerName.toLowerCase().contains(_searchQuery);
        final phoneMatch = c.customerPhone.toLowerCase().contains(_searchQuery);
        final orderMatch = c.orderNumber?.toLowerCase().contains(_searchQuery) ?? false;
        final msgMatch = c.lastMessage.toLowerCase().contains(_searchQuery);
        return nameMatch || phoneMatch || orderMatch || msgMatch;
      }).toList();
    }

    return chats;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isSuper = user?.isSuperAdmin ?? false;
    final isLarge = MediaQuery.of(context).size.width >= 720;
    final chatProv = context.watch<ChatProvider>();

    final filteredChats = _filterChats(chatProv.adminChats);

    // If a chat was selected on mobile and user tapped back
    if (!isLarge && _selectedChat != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        appBar: _buildThreadAppBar(isLarge: false),
        body: _buildThreadView(isLarge: false),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      drawer: const AdminCollapsibleSidebar(currentRoute: '/admin/chats'),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Customer Support Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
            tooltip: 'Refresh Chats',
            onPressed: () => _initAdminChatStream(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.brandYellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Open (${chatProv.adminChats.where((c) => c.status == 'open').length})'),
            Tab(text: 'Pending (${chatProv.adminChats.where((c) => c.status == 'pending').length})'),
            Tab(text: 'Resolved (${chatProv.adminChats.where((c) => c.status == 'resolved').length})'),
            Tab(text: 'All (${chatProv.adminChats.length})'),
          ],
        ),
      ),
      body: isLarge
          ? Row(
              children: [
                SizedBox(
                  width: 380,
                  child: _buildChatListPane(filteredChats, isSuper),
                ),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: _selectedChat != null
                      ? _buildThreadView(isLarge: true)
                      : _buildNoChatSelectedPlaceholder(),
                ),
              ],
            )
          : _buildChatListPane(filteredChats, isSuper),
    );
  }

  Widget _buildChatListPane(List<ChatModel> chats, bool isSuper) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final branchProv = context.watch<BranchProvider>();

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(12),
          color: colorScheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                style: TextStyle(fontSize: 13.5, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search customer, phone, order #...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if ((isSuper || (user?.branchId == null || user!.branchId!.isEmpty || user.branchId == 'all')) && branchProv.branches.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Branches', style: TextStyle(fontSize: 11.5)),
                        selected: _selectedBranchFilter == null || _selectedBranchFilter!.isEmpty,
                        onSelected: (_) {
                          setState(() => _selectedBranchFilter = null);
                          _initAdminChatStream();
                        },
                      ),
                      const SizedBox(width: 6),
                      ...branchProv.branches.map((b) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(b.name, style: const TextStyle(fontSize: 11.5)),
                            selected: _selectedBranchFilter == b.id,
                            onSelected: (sel) {
                              setState(() => _selectedBranchFilter = sel ? b.id : null);
                              _initAdminChatStream();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No customer chats in this view',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isSelected = _selectedChat?.id == chat.id;
                    final hasUnread = chat.unreadForAdmin > 0;
                    final timeStr = DateFormat('h:mm a').format(chat.lastMessageAt);

                    return Material(
                      color: isSelected
                          ? (isDark ? AppColors.darkSurfaceElevated : AppColors.yellowSoft.withValues(alpha: 0.35))
                          : Colors.transparent,
                      child: ListTile(
                        selected: isSelected,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: hasUnread
                                  ? AppColors.brandYellow
                                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted),
                              child: Text(
                                chat.customerName.isNotEmpty ? chat.customerName[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hasUnread
                                      ? AppColors.onYellow
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          if (hasUnread)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${chat.unreadForAdmin}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.customerName,
                              style: TextStyle(
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Chat started',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: hasUnread
                                  ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (chat.orderId != null && chat.orderId!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${chat.orderNumber ?? chat.orderId!.substring(0, 6)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: chat.status == 'resolved'
                                      ? AppColors.successSoft
                                      : (chat.status == 'pending' ? AppColors.warningSoft : AppColors.infoSoft),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  chat.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: chat.status == 'resolved'
                                        ? AppColors.success
                                        : (chat.status == 'pending' ? AppColors.warning : AppColors.info),
                                  ),
                                ),
                              ),
                              if (isSuper)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chat.branchId,
                                    style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _selectChat(chat),
                    ),
                  );
                  },
                ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildThreadAppBar({required bool isLarge}) {
    final chat = _selectedChat;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final chatProv = context.read<ChatProvider>();

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: isLarge
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => setState(() => _selectedChat = null),
            ),
      title: chat == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.customerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                  ),
                ),
                Text(
                  chat.customerPhone.isNotEmpty
                      ? '${chat.customerPhone} • Branch: ${chat.branchId}'
                      : 'Branch: ${chat.branchId}',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
      actions: [
        if (chat != null) ...[
          if (chat.status == 'resolved')
            TextButton.icon(
              icon: Icon(Icons.replay_rounded, size: 18, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
              label: Text('Reopen', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon)),
              onPressed: () {
                chatProv.updateStatus(
                  'open',
                  actorName: user?.name ?? 'Admin',
                  actorEmail: user?.email ?? '',
                  actorRole: user?.role ?? 'admin',
                );
                setState(() => _selectedChat = _selectedChat?.copyWith(status: 'open'));
              },
            )
          else
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.successSoft,
                foregroundColor: AppColors.success,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Mark Resolved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                chatProv.updateStatus(
                  'resolved',
                  actorName: user?.name ?? 'Admin',
                  actorEmail: user?.email ?? '',
                  actorRole: user?.role ?? 'admin',
                );
                setState(() => _selectedChat = _selectedChat?.copyWith(status: 'resolved'));
              },
            ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildThreadView({required bool isLarge}) {
    final chat = _selectedChat;
    if (chat == null) return _buildNoChatSelectedPlaceholder();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chatProv = context.watch<ChatProvider>();

    return Column(
      children: [
        if (isLarge) _buildThreadAppBar(isLarge: true),

        // Order Context Strip if order linked
        if (chat.orderId != null && chat.orderId!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.yellowTint,
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Linked to Order #${chat.orderNumber ?? chat.orderId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                    side: BorderSide(color: isDark ? AppColors.brandYellow : AppColors.brandMaroon, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _openOrderModal(chat.orderId!),
                ),
              ],
            ),
          ),

        // Resolved State Strip
        if (chat.status == 'resolved')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.successSoft,
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text(
                  'This chat is resolved. Replying will automatically reopen it.',
                  style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

        // Message Thread
        Expanded(
          child: chatProv.isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : chatProv.activeMessages.isEmpty
                  ? const Center(
                      child: Text('No messages yet in this channel.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: chatProv.activeMessages.length,
                      itemBuilder: (context, index) {
                        final msg = chatProv.activeMessages[index];
                        final isAdmin = msg.isAdmin;
                        final timeStr = DateFormat('h:mm a').format(msg.createdAt);

                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? (isDark ? AppColors.maroonDeep : AppColors.brandMaroon)
                                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.surface),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                                bottomRight: Radius.circular(isAdmin ? 4 : 14),
                              ),
                              border: isAdmin
                                  ? null
                                  : Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Column(
                              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    isAdmin ? (msg.senderName.isNotEmpty ? msg.senderName : 'Support') : chat.customerName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                          ? AppColors.brandYellow
                                          : (isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                                    ),
                                  ),
                                ),
                                if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        msg.imageUrl!,
                                        fit: BoxFit.cover,
                                        height: 180,
                                      ),
                                    ),
                                  ),
                                if (msg.text.isNotEmpty)
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: isAdmin
                                          ? Colors.white
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isAdmin
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Canned Replies Carousel
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _cannedReplies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final reply = _cannedReplies[index];
              return ActionChip(
                label: Text(reply, style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon)),
                backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.yellowSoft,
                side: isDark ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none,
                onPressed: () => _handleAdminSend(customText: reply),
              );
            },
          ),
        ),

        // Admin Input Composer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo_camera_back_outlined, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
                tooltip: 'Attach Image',
                onPressed: _handleAttachImage,
              ),
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type admin response...',
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _handleAdminSend(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isComposing
                      ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                      : (isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _isComposing
                        ? (isDark ? AppColors.brandMaroon : AppColors.brandYellow)
                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  ),
                  onPressed: _isComposing ? () => _handleAdminSend() : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoChatSelectedPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a customer inquiry from the left panel to begin replying.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
