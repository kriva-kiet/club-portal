import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_providers.dart';
import '../core/theme/app_colors.dart';
import 'glass_container.dart';
import 'app_avatar.dart';

class UserListSheet extends ConsumerStatefulWidget {
  final String title;
  final List<String> userIds;

  const UserListSheet({
    super.key,
    required this.title,
    required this.userIds,
  });

  static void show(BuildContext context, {required String title, required List<String> userIds}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => UserListSheet(title: title, userIds: userIds),
    );
  }

  @override
  ConsumerState<UserListSheet> createState() => _UserListSheetState();
}

class _UserListSheetState extends ConsumerState<UserListSheet> {
  final Set<String> _optimisticFollows = {};
  final Set<String> _optimisticUnfollows = {};

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.userIds.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 20),
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  final filteredMembers = members.where((m) => widget.userIds.contains(m.uid)).toList();

                  if (filteredMembers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No members to display.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final user = filteredMembers[index];
                      final isMe = currentUser != null && currentUser.uid == user.uid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              AppAvatar(
                                photoUrl: user.photoUrl,
                                name: user.name,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${user.role.name.toUpperCase()} • ${user.batch}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentUser != null && !isMe)
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
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
        );
      },
    );
  }
}

