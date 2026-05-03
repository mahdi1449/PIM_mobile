import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';

class ClassementTab extends StatelessWidget {
  const ClassementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.leaderboard.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        final leaderboard = provider.leaderboard;
        final currentUserId = provider.currentProfile?.userId;

        return Column(
          children: [
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchLeaderboard(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 30),
                    if (leaderboard.isNotEmpty) _buildPodium(leaderboard),
                    const SizedBox(height: 40),
                    _buildLeaderboardList(leaderboard, currentUserId),
                    const SizedBox(height: 20),
                    _buildEgoProtectionNote(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: _filterButton('ÉQUIPE', true)),
            Expanded(child: _filterButton('POSTE', false)),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Colors.purpleAccent, Color(0xFF6366F1)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<dynamic> leaderboard) {
    final top1 = leaderboard.length > 0 ? leaderboard[0] : null;
    final top2 = leaderboard.length > 1 ? leaderboard[1] : null;
    final top3 = leaderboard.length > 2 ? leaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top2 != null) _podiumItem(top2, 2, 90, Colors.blueGrey),
          const SizedBox(width: 12),
          if (top1 != null) _podiumItem(top1, 1, 120, Colors.amber),
          const SizedBox(width: 12),
          if (top3 != null) _podiumItem(top3, 3, 75, Colors.brown),
        ],
      ),
    );
  }

  Widget _podiumItem(
    dynamic player,
    int rank,
    double height,
    Color accentColor,
  ) {
    bool isFirst = rank == 1;
    String name = player['fullName'] ?? player['firstName'] ?? 'JOUEUR';
    String pts = '${player['monthlyPoints']} PTS';
    String initials = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isFirst ? 34 : 26,
                backgroundColor: const Color(0xFF161926),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: -22,
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.2),
                accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          pts,
          style: TextStyle(
            color: accentColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(
    List<dynamic> leaderboard,
    String? currentUserId,
  ) {
    return Column(
      children: List.generate(leaderboard.length, (index) {
        final player = leaderboard[index];
        final rank = index + 1;
        final isSelf = player['userId'] == currentUserId;
        final isTop3 = rank <= 3;
        final isHidden = !isTop3 && !isSelf;

        String name = isHidden
            ? 'POSITION MASQUÉE'
            : (player['fullName'] ?? player['firstName'] ?? 'JOUEUR')
                  .toString()
                  .toUpperCase();
        if (isSelf) name += ' (VOUS)';

        String pts = isHidden ? '--' : '${player['monthlyPoints']}';
        Color rankColor = rank == 1
            ? Colors.amber
            : (rank == 2
                  ? Colors.blueGrey
                  : (rank == 3 ? Colors.brown : Colors.white38));

        return _leaderboardTile(
          rank,
          name,
          pts,
          rankColor,
          isTop3,
          isSelf: isSelf,
          isHidden: isHidden,
        );
      }),
    );
  }

  Widget _leaderboardTile(
    int rank,
    String name,
    String pts,
    Color rankColor,
    bool isTop, {
    bool isSelf = false,
    bool isHidden = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelf
            ? Colors.purpleAccent.withOpacity(0.1)
            : const Color(0xFF1E2130).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelf
              ? Colors.purpleAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withOpacity(0.3)),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isHidden
                  ? Colors.white10
                  : const Color(0xFF161926),
              child: Text(
                isHidden ? '?' : name[0],
                style: TextStyle(
                  fontSize: 14,
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isHidden ? Colors.white24 : Colors.white,
                fontWeight: isSelf ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pts,
                style: TextStyle(
                  color: isHidden ? Colors.white10 : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const Text(
                'PTS',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEgoProtectionNote() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white24, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seul le top 3 est visible de tous. Les autres ne voient que leur propre position. Le classement se remet à zéro chaque mois.',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
