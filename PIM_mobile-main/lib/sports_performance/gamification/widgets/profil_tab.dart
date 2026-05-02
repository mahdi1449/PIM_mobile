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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildUserHeader(),
        const SizedBox(height: 40),
        _buildProgressionCard(),
        const SizedBox(height: 40),
        _buildQuickStats(),
        const SizedBox(height: 48),
        _buildActionHistory(),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purpleAccent, Colors.cyanAccent],
            ),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF161926),
            child: Text(
              initials, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName ?? 'JOUEUR ÉLITE',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.2), Colors.red.withOpacity(0.2)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          profile.currentLevel.toUpperCase(), 
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${profile.monthlyPoints} PTS / MOIS',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROCHAINE ÉTAPE : ${profile.nextLevel.toUpperCase()}', 
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
              ),
              Text(
                '${profile.totalPoints} / ${profile.targetPoints} PTS', 
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w900)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 12,
                width: profile.progression * 300, // Approximate width multiplier
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.cyanAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ENCORE ${profile.targetPoints - profile.totalPoints} POINTS POUR PASSER AU NIVEAU SUPÉRIEUR',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statItem('${profile.totalPoints}', 'TOTAL', Icons.emoji_events_outlined, Colors.amberAccent),
        const SizedBox(width: 12),
        _statItem('12', 'BADGES', Icons.workspace_premium_outlined, Colors.purpleAccent),
        const SizedBox(width: 12),
        _statItem('3ème', 'RANG', Icons.leaderboard_outlined, Colors.orangeAccent),
        const SizedBox(width: 12),
        _statItem('${profile.activeStreak}j', 'SÉRIE', Icons.local_fire_department_outlined, Colors.redAccent),
      ],
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_toggle_off, color: Colors.purpleAccent, size: 20),
            SizedBox(width: 10),
            Text(
              'HISTORIQUE DE PERFORMANCE',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...recentActions.map((action) => _buildActionTile(action)),
      ],
    );
  }

  Widget _buildActionTile(ActionLog action) {
    IconData icon = Icons.check_circle_outline;
    Color color = Colors.cyanAccent;
    
    if (action.type.contains('NUTRITION')) {
      icon = Icons.restaurant_outlined;
      color = Colors.orangeAccent;
    } else if (action.type.contains('COGNITIVE')) {
      icon = Icons.psychology_outlined;
      color = Colors.blueAccent;
    } else if (action.type.contains('MATCH')) {
      icon = Icons.sports_soccer_outlined;
      color = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.type.replaceAll('_', ' '), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)
                ),
                Text(
                  '${action.module.toUpperCase()} • ${action.timeAgo.toUpperCase()}', 
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
              ],
            ),
          ),
          Text(
            '+${action.points}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(width: 4),
          Text('PTS', style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
