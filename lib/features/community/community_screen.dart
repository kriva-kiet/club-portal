import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../models/post_model.dart';
import '../../services/service_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/linkable_text.dart';
import '../../widgets/user_list_sheet.dart';
import '../../widgets/app_footer.dart';
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
                  Icon(
                    Icons.people_alt_rounded,
                    color: Theme.of(context).colorScheme.primary,
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
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: 'Members'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_FeedTab(), _MembersTab()],
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
                    // Trigger local notification
                    await NotificationService.showPostNotification(
                      title: user.name,
                      body: post.text.length > 80
                          ? '${post.text.substring(0, 80)}…'
                          : post.text,
                    );
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
                          Icon(
                            Icons.comment_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
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
                                    AppAvatar(
                                      photoUrl: comment.authorPhoto,
                                      name: comment.authorName,
                                      radius: 16,
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
                                          LinkableText(
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
                              final commentText = commentController.text.trim();
                              commentController.clear();
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .addComment(post.id, comment);

                              // Notify post author if commenter is not the author
                              if (post.authorUid != user.uid) {
                                final preview = commentText.length > 60
                                    ? '${commentText.substring(0, 60)}…'
                                    : commentText;
                                await NotificationService.sendDirectNotification(
                                  recipientUid: post.authorUid,
                                  type: 'comment',
                                  title: '${user.name} commented on your post',
                                  body: preview,
                                  extraData: {'postId': post.id},
                                );
                              }
                            },
                            icon: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).colorScheme.primary,
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

  Future<void> _confirmDeletePost(BuildContext context, String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(databaseRepositoryProvider).deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully! 🗑️'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider(_selectedTag));
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostSheet(context, user),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.border,
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

                // Sort posts: priority to following members, then descending by date
                final sortedPosts = List<PostModel>.from(posts);
                sortedPosts.sort((a, b) {
                  final aFollowed = user.followingIds.contains(a.authorUid);
                  final bFollowed = user.followingIds.contains(b.authorUid);
                  
                  if (aFollowed && !bFollowed) return -1;
                  if (!aFollowed && bFollowed) return 1;
                  return b.createdAt.compareTo(a.createdAt); // both followed or both unfollowed, newest first
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: sortedPosts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == sortedPosts.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 32),
                        child: AppFooter(),
                      );
                    }
                    final post = sortedPosts[index];
                    final hasLiked = post.likes.contains(user.uid);

                    final canDelete = post.authorUid == user.uid ||
                        user.role == UserRole.admin ||
                        user.role == UserRole.developer;

                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppAvatar(
                                photoUrl: post.authorPhoto,
                                name: post.authorName,
                                radius: 18,
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
                                  color: Theme.of(context).colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '#${post.tag}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (canDelete) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete post',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDeletePost(context, post.id),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinkableText(
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
                                onPressed: () async {
                                  final willLike = !hasLiked;
                                  await ref
                                      .read(databaseRepositoryProvider)
                                      .toggleLikePost(user.uid, post.id);

                                  if (willLike && post.authorUid != user.uid) {
                                    final preview = post.text.length > 50
                                        ? '${post.text.substring(0, 50)}…'
                                        : post.text;
                                    await NotificationService.sendDirectNotification(
                                      recipientUid: post.authorUid,
                                      type: 'like',
                                      title: '${user.name} liked your post',
                                      body: preview.isEmpty ? 'Your post received a new like!' : preview,
                                      extraData: {'postId': post.id},
                                    );
                                  }
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
    final membersAsync = ref.watch(_communityMembersProvider);
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
            
            String displayTitle = channel.name;
            String subtitle = '';
            IconData icon = Icons.forum_rounded;
            String? photoUrl;

            if (channel.type == 'direct') {
              icon = Icons.person_rounded;
              subtitle = channel.lastMessage ?? 'Started a chat';
              
              // Resolve other participant
              final otherUserId = channel.participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );
              
              if (otherUserId.isNotEmpty) {
                membersAsync.whenData((members) {
                  final otherUser = members.firstWhere(
                    (m) => m.uid == otherUserId,
                    orElse: () => user, // fallback (shouldn't happen)
                  );
                  if (otherUser.uid == otherUserId) {
                    displayTitle = otherUser.name;
                    photoUrl = otherUser.photoUrl;
                  }
                });
              }
            } else if (channel.type == 'domain') {
              icon = Icons.tag_rounded;
              subtitle = 'Domain Discussion';
            } else {
              icon = Icons.campaign_rounded;
              subtitle = 'General Channel';
            }

            final displayChannel = channel.type == 'direct' ? ChatChannelModel(
              id: channel.id,
              name: displayTitle,
              type: channel.type,
              participants: channel.participants,
              lastMessage: channel.lastMessage,
              updatedAt: channel.updatedAt,
              domainId: channel.domainId,
            ) : channel;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: AppAvatar(
                  photoUrl: photoUrl,
                  name: displayTitle,
                  radius: 20,
                ),
                title: Text(
                  displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onTap: () => _openChatRoom(context, displayChannel, user),
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
                            AppAvatar(
                              photoUrl: msg.senderPhoto,
                              name: msg.senderName,
                              radius: 14,
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
                                    ? Theme.of(context).colorScheme.primary
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
                                  LinkableText(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                    linkStyle: TextStyle(
                                      color: isMe
                                          ? Colors.yellowAccent
                                          : Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
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
                  icon: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).colorScheme.primary,
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

// ── Members Tab ───────────────────────────────────────────────────────────
final _communityMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final db = ref.watch(databaseRepositoryProvider);
  return db.getMembers();
});

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab();

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  final _searchController = TextEditingController();
  final Set<String> _optimisticFollows = {};
  final Set<String> _optimisticUnfollows = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    String finalUrl = trimmed;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    try {
      final uri = Uri.parse(finalUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $finalUrl')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $finalUrl')),
        );
      }
    }
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchExternalUrl(url),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: backgroundColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_outward_rounded,
                size: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_communityMembersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return membersAsync.when(
      data: (allMembers) {
        if (allMembers.isEmpty) {
          return const Center(
            child: Text(
              'No members found.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        final query = _searchController.text.trim().toLowerCase();
        
        // Filter by search query
        var filteredMembers = allMembers.where((u) {
          return u.name.toLowerCase().contains(query) ||
                 u.role.name.toLowerCase().contains(query) ||
                 u.batch.toLowerCase().contains(query);
        }).toList();

        // Sort alphabetically by name
        filteredMembers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredMembers.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching members.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final user = filteredMembers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppAvatar(
                                      photoUrl: user.photoUrl,
                                      name: user.name,
                                      radius: 24,
                                      borderWidth: 1.5,
                                      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${user.role.name.toUpperCase()} • ${user.batch}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentUser != null && currentUser.uid != user.uid) ...[
                                      // Message Button (only if followed)
                                      if (currentUser.followingIds.contains(user.uid))
                                        IconButton(
                                          icon: const Icon(Icons.message_rounded, color: AppColors.primary),
                                          onPressed: () async {
                                            final channelId = await ref.read(databaseRepositoryProvider)
                                                .getOrCreateDirectChat(currentUser.uid, user.uid);
                                            
                                            if (context.mounted) {
                                              final dummyChannel = ChatChannelModel(
                                                id: channelId,
                                                name: user.name,
                                                type: 'direct',
                                                participants: [currentUser.uid, user.uid],
                                              );
                                              
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => _ChatRoomScreen(
                                                    channel: dummyChannel,
                                                    currentUser: currentUser,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      // Follow/Unfollow Button
                                      Builder(
                                        builder: (context) {
                                          bool isFollowing = currentUser.followingIds.contains(user.uid);
                                          if (_optimisticFollows.contains(user.uid)) isFollowing = true;
                                          if (_optimisticUnfollows.contains(user.uid)) isFollowing = false;

                                          return TextButton(
                                            onPressed: () async {
                                              setState(() {
                                                if (isFollowing) {
                                                  _optimisticFollows.remove(user.uid);
                                                  _optimisticUnfollows.add(user.uid);
                                                } else {
                                                  _optimisticFollows.add(user.uid);
                                                  _optimisticUnfollows.remove(user.uid);
                                                }
                                              });
                                              await ref.read(databaseRepositoryProvider)
                                                  .toggleFollowMember(currentUser.uid, user.uid, !isFollowing);
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: isFollowing 
                                                  ? AppColors.surfaceLight 
                                                  : AppColors.primary,
                                              foregroundColor: isFollowing
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            child: Text(
                                              isFollowing ? 'Following' : 'Follow',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Followers & Following Stats Row
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        UserListSheet.show(
                                          context,
                                          title: '${user.name}\'s Followers',
                                          userIds: user.followerIds,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.people_outline_rounded,
                                              size: 14,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${user.followerIds.length}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Followers',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () {
                                        UserListSheet.show(
                                          context,
                                          title: '${user.name} is Following',
                                          userIds: user.followingIds,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.person_add_alt_1_outlined,
                                              size: 14,
                                              color: AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${user.followingIds.length}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Following',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.bio.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    user.bio,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                if (user.githubId.isNotEmpty || user.linkedinId.isNotEmpty || user.instagramId.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.border),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (user.githubId.isNotEmpty)
                                        _buildSocialButton(
                                          label: 'GitHub',
                                          icon: Icons.code_rounded,
                                          color: Colors.white,
                                          backgroundColor: const Color(0xFF24292E),
                                          url: user.githubId.startsWith('http')
                                              ? user.githubId
                                              : 'https://github.com/${user.githubId.replaceAll('@', '')}',
                                        ),
                                      if (user.linkedinId.isNotEmpty)
                                        _buildSocialButton(
                                          label: 'LinkedIn',
                                          icon: Icons.business_center_rounded,
                                          color: const Color(0xFF70B5F9),
                                          backgroundColor: const Color(0xFF0A66C2),
                                          url: user.linkedinId.startsWith('http')
                                              ? user.linkedinId
                                              : 'https://www.linkedin.com/in/${user.linkedinId.replaceAll('@', '')}',
                                        ),
                                      if (user.instagramId.isNotEmpty)
                                        _buildSocialButton(
                                          label: 'Instagram',
                                          icon: Icons.camera_alt_rounded,
                                          color: const Color(0xFFFF85A2),
                                          backgroundColor: const Color(0xFFE1306C),
                                          url: user.instagramId.startsWith('http')
                                              ? user.instagramId
                                              : 'https://instagram.com/${user.instagramId.replaceAll('@', '')}',
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading members: $error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}

