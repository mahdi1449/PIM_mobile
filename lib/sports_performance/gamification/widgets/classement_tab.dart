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
          return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _filterButton('Équipe', true)),
          const SizedBox(width: 12),
          Expanded(child: _filterButton('Mon poste', false)),
        ],
      ),
    );
  }

  Widget _filterButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1C1F2E) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? Colors.white24 : Colors.white10),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<dynamic> leaderboard) {
    // Get top 3
    final top1 = leaderboard.length > 0 ? leaderboard[0] : null;
    final top2 = leaderboard.length > 1 ? leaderboard[1] : null;
    final top3 = leaderboard.length > 2 ? leaderboard[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top2 != null) _podiumItem(top2, 2, 70),
        const SizedBox(width: 15),
        if (top1 != null) _podiumItem(top1, 1, 90),
        const SizedBox(width: 15),
        if (top3 != null) _podiumItem(top3, 3, 60),
      ],
    );
  }

  Widget _podiumItem(dynamic player, int rank, double height) {
    bool isFirst = rank == 1;
    String name = player['fullName'] ?? player['firstName'] ?? 'Joueur';
    String pts = '${player['monthlyPoints']} pts';
    String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isFirst ? Colors.amber : Colors.white24, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueGrey.shade900,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: -15,
                child: Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFirst 
                ? [const Color(0xFFE6B800), const Color(0xFF997A00)] 
                : [const Color(0xFF2E3243), const Color(0xFF1C1F2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$rankè', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(pts, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildLeaderboardList(List<dynamic> leaderboard, String? currentUserId) {
    return Column(
      children: List.generate(leaderboard.length, (index) {
        final player = leaderboard[index];
        final rank = index + 1;
        final isSelf = player['userId'] == currentUserId;
        final isTop3 = rank <= 3;

        // Protection de l'Ego: si pas dans le top 3 et pas soi-même, on masque
        final isHidden = !isTop3 && !isSelf;

        String name = isHidden ? 'Position masquée' : (player['fullName'] ?? player['firstName'] ?? 'Joueur');
        if (isSelf) name += ' (Vous)';
        
        String pts = isHidden ? '--' : '${player['monthlyPoints']}';
        Color rankColor = isTop3 ? Colors.amber : Colors.white70;

        return _leaderboardTile(rank, name, pts, rankColor, isTop3, isSelf: isSelf, isHidden: isHidden);
      }),
    );
  }

  Widget _leaderboardTile(int rank, String name, String pts, Color rankColor, bool isTop, {bool isSelf = false, bool isHidden = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelf ? Colors.deepPurple.withOpacity(0.2) : const Color(0xFF161926),
        borderRadius: BorderRadius.circular(12),
        border: isSelf ? Border.all(color: Colors.deepPurple.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: isHidden ? Colors.white10 : Colors.blueGrey.shade800,
            child: Text(isHidden ? '?' : name[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isHidden ? Colors.white24 : Colors.white,
                fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            pts,
            style: TextStyle(color: isHidden ? Colors.white10 : Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEgoProtectionNote() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        'Seul le top 3 est visible de tous. Les autres ne voient que leur propre position. Le classement se remet à zéro chaque mois.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white24, fontSize: 11),
      ),
    );
  }
}
