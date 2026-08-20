import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../widgets/glass_container.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Leaderboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No users in the leaderboard yet.'),
            );
          }

          // Ranks 1, 2, and 3
          final podiumUsers = users.take(3).toList();
          final listUsers = users.skip(3).toList();

          return Column(
            children: [
              // Visual Podium
              if (podiumUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Rank 2 (Silver)
                      if (podiumUsers.length > 1)
                        _buildPodiumItem(
                          context,
                          user: podiumUsers[1],
                          rank: 2,
                          color: const Color(0xFFC0C0C0), // Silver
                          height: 120,
                          avatarSize: 64,
                        ),

                      // Rank 1 (Gold)
                      _buildPodiumItem(
                        context,
                        user: podiumUsers[0],
                        rank: 1,
                        color: const Color(0xFFFFD700), // Gold
                        height: 150,
                        avatarSize: 76,
                      ),

                      // Rank 3 (Bronze)
                      if (podiumUsers.length > 2)
                        _buildPodiumItem(
                          context,
                          user: podiumUsers[2],
                          rank: 3,
                          color: const Color(0xFFCD7F32), // Bronze
                          height: 100,
                          avatarSize: 58,
                        ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Ranks 4+ Scrollable List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listUsers.length,
                  itemBuilder: (context, index) {
                    final user = listUsers[index];
                    final rank = index + 4;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$rank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: user.photoUrl.isNotEmpty
                                  ? NetworkImage(user.photoUrl)
                                  : null,
                              child: user.photoUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          ],
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          user.batch,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.streak.count}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
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
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPodiumItem(
    BuildContext context, {
    required dynamic user,
    required int rank,
    required Color color,
    required double height,
    required double avatarSize,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Avatar with glowing rank outline
            Container(
              width: avatarSize + 6,
              height: avatarSize + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: user.photoUrl.isNotEmpty
                    ? Image.network(user.photoUrl, fit: BoxFit.cover)
                    : const Icon(Icons.person, color: AppColors.textSecondary),
              ),
            ),
            // Rank Badge Number
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.name.split(' ').first,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.accent,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              '${user.streak.count}',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Podium Column Block
        GlassContainer(
          width: 80,
          height: height,
          borderRadius: 8,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
