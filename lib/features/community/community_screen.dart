import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../models/post_model.dart';
import '../../services/service_providers.dart';
import '../../widgets/glass_container.dart';
import '../../core/localization/app_localizations.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.translate('community_title') ??
                        'Community Hub',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: 'Chats'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_FeedTab(), _ChatsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed Tab ──────────────────────────────────────────────────────────────
class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab();

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  String _selectedTag = 'all';

  final List<Map<String, String>> _tags = [
    {'id': 'all', 'label': 'All Feed'},
    {'id': 'general', 'label': '#general'},
    {'id': 'dsa', 'label': '#DSA'},
    {'id': 'web_dev', 'label': '#web-dev'},
    {'id': 'hackathon', 'label': '#hackathon'},
  ];

  void _showNewPostSheet(BuildContext context, dynamic user) {
    final textController = TextEditingController();
    String activeTag = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Post',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Share updates, ask questions, or link resources...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Tag:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _tags.where((t) => t['id'] != 'all').map((tag) {
                    final isSel = activeTag == tag['id'];
                    return ChoiceChip(
                      label: Text(tag['label']!),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setModalState(() => activeTag = tag['id']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    final post = PostModel(
                      id: const Uuid().v4(),
                      authorUid: user.uid,
                      authorName: user.name,
                      authorPhoto: user.photoUrl,
                      text: textController.text.trim(),
                      tag: activeTag,
                      likes: [],
                      commentCount: 0,
                      createdAt: DateTime.now(),
                    );
                    await ref.read(databaseRepositoryProvider).createPost(post);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Post to Community'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, PostModel post, dynamic user) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final commentsAsync = ref.watch(commentsProvider(post.id));

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.comment_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Comments (${post.commentCount})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'No comments yet. Start the conversation!',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          comment.authorPhoto.isNotEmpty
                                          ? NetworkImage(comment.authorPhoto)
                                          : null,
                                      child: comment.authorPhoto.isEmpty
                                          ? const Icon(Icons.person, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment.authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat(
                                                  'hh:mm a',
                                                ).format(comment.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.text,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      color: AppColors.surface,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Write a comment...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              if (commentController.text.trim().isEmpty) return;
                              final comment = CommentModel(
                                id: const Uuid().v4(),
                                authorUid: user.uid,
                                authorName: user.name,
                                authorPhoto: user.photoUrl,
                                text: commentController.text.trim(),
                                createdAt: DateTime.now(),
                              );
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .addComment(post.id, comment);
                              commentController.clear();
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider(_selectedTag));
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostSheet(context, user),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Tags Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      tag['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTag = tag['id']!);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No community updates yet in this tag.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final hasLiked = post.likes.contains(user.uid);

                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: post.authorPhoto.isNotEmpty
                                    ? NetworkImage(post.authorPhoto)
                                    : null,
                                child: post.authorPhoto.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'MMM dd, hh:mm a',
                                      ).format(post.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '#${post.tag}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              // Like Button
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(databaseRepositoryProvider)
                                      .toggleLikePost(user.uid, post.id);
                                },
                                icon: Icon(
                                  hasLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  color: hasLiked
                                      ? Colors.redAccent
                                      : AppColors.textMuted,
                                ),
                              ),
                              Text(
                                '${post.likes.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Comment Button
                              IconButton(
                                onPressed: () =>
                                    _showCommentsSheet(context, post, user),
                                icon: const Icon(
                                  Icons.comment_outlined,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                '${post.commentCount}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chats Tab ───────────────────────────────────────────────────────────────
class _ChatsTab extends ConsumerWidget {
  const _ChatsTab();

  void _openChatRoom(
    BuildContext context,
    ChatChannelModel channel,
    dynamic user,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ChatRoomScreen(channel: channel, currentUser: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(
            child: Text(
              'No chat channels created yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            final icon = channel.type == 'domain'
                ? Icons.tag_rounded
                : Icons.campaign_rounded;
            final subtitle = channel.type == 'domain'
                ? 'Domain Discussion'
                : 'General Channel';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  channel.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onTap: () => _openChatRoom(context, channel, user),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Chat Room Screen ─────────────────────────────────────────────────────────
class _ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatChannelModel channel;
  final dynamic currentUser;

  const _ChatRoomScreen({required this.channel, required this.currentUser});

  @override
  ConsumerState<_ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<_ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.channel.id));

    // Schedule scroll to bottom when new messages come in
    ref.listen(messagesProvider(widget.channel.id), (prev, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.channel.name), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages here yet. Say hi! 👋',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                // Scroll on first load
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == widget.currentUser.uid;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: msg.senderPhoto.isNotEmpty
                                  ? NetworkImage(msg.senderPhoto)
                                  : null,
                              child: msg.senderPhoto.isEmpty
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: isMe
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  if (!isMe) const SizedBox(height: 2),
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      DateFormat('hh:mm a').format(msg.sentAt),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isMe
                                            ? Colors.white70
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendChatMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final message = MessageModel(
      id: const Uuid().v4(),
      senderUid: widget.currentUser.uid,
      senderName: widget.currentUser.name,
      senderPhoto: widget.currentUser.photoUrl,
      text: _msgController.text.trim(),
      sentAt: DateTime.now(),
    );

    await ref
        .read(databaseRepositoryProvider)
        .sendMessage(widget.channel.id, message);
    _msgController.clear();
  }
}
