import 'package:flutter/material.dart';
import '../models/gamification_models.dart';

class ProfilTab extends StatelessWidget {
  final GamificationProfile profile;
  final List<ActionLog> recentActions;
  final String? playerName;

  const ProfilTab({
    super.key,
    required this.profile,
    required this.recentActions,
    this.playerName,
  });

  String get initials {
    if (playerName == null || playerName!.isEmpty) return '??';
    List<String> parts = playerName!.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildUserHeader(),
        const SizedBox(height: 24),
        _buildProgressionCard(),
        const SizedBox(height: 24),
        _buildQuickStats(),
        const SizedBox(height: 32),
        _buildActionHistory(),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueGrey.shade800,
          child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName ?? 'Joueur',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Text(
                  'Niveau ${profile.currentLevel} • ${profile.monthlyPoints} pts ce mois',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.orange, size: 14),
                      Text(' Pro', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progression vers ${profile.nextLevel}', style: const TextStyle(color: Colors.white70)),
            Text('${profile.totalPoints} / ${profile.targetPoints} pts', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: profile.progression,
            minHeight: 12,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statItem('${profile.totalPoints}', 'Points totaux'),
        const SizedBox(width: 12),
        _statItem('12', 'Badges'),
        const SizedBox(width: 12),
        _statItem('3ème', 'Classement'),
        const SizedBox(width: 12),
        _statItem('${profile.activeStreak}j', 'Série active'),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Derniers points gagnés',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...recentActions.map((action) => _buildActionTile(action)),
      ],
    );
  }

  Widget _buildActionTile(ActionLog action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('${action.module} • ${action.timeAgo}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Text(
            '+${action.points} pts',
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
