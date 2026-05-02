import 'package:flutter/material.dart';

class BaremeTab extends StatelessWidget {
  const BaremeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Comment gagner des points ?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Accumulez des points pour monter en niveau et débloquer des récompenses.',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(height: 24),
        _buildCategory('🧠 PERFORMANCE COGNITIVE', [
          _baremeItem('Test Cognitif complété', '+10 pts', Icons.psychology),
          _baremeItem('Score IA > 90%', '+20 pts', Icons.star),
        ]),
        _buildCategory('🥗 SANTÉ & NUTRITION', [
          _baremeItem('Journal nutritionnel rempli', '+5 pts', Icons.restaurant),
          _baremeItem('Sommeil > 8h logué', '+10 pts', Icons.bedtime),
        ]),
        _buildCategory('⚽ TERRAIN & MATCH', [
          _baremeItem('Présence entraînement', '+15 pts', Icons.sports_soccer),
          _baremeItem('But ou Passe décisive', '+50 pts', Icons.emoji_events),
          _baremeItem('Clean sheet (Défenseurs)', '+40 pts', Icons.shield),
        ]),
        _buildCategory('👨‍🏫 STAFF & DISCIPLINE', [
          _baremeItem('Évaluation coach > 8/10', '+25 pts', Icons.thumb_up),
          _baremeItem('Zéro carton (Mois)', '+100 pts', Icons.verified),
        ]),
      ],
    );
  }

  Widget _buildCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
          ),
        ),
        ...items,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _baremeItem(String label, String points, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          Text(points, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
