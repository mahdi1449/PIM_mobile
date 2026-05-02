import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification_models.dart';
import '../widgets/profil_tab.dart';
import '../widgets/classement_tab.dart';
import '../widgets/bareme_tab.dart';
import '../providers/gamification_provider.dart';

class GamificationDashboardScreen extends StatefulWidget {
  final String? playerId;
  final String? playerName;

  const GamificationDashboardScreen({
    super.key,
    this.playerId,
    this.playerName,
  });

  @override
  State<GamificationDashboardScreen> createState() => _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState extends State<GamificationDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Charger les données réelles au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.playerId != null && widget.playerId!.isNotEmpty) {
        context.read<GamificationProvider>().fetchProfile(widget.playerId!);
      }
      context.read<GamificationProvider>().fetchLeaderboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getSafePlayerName() {
    if (widget.playerName == null || widget.playerName == 'null null' || widget.playerName!.isEmpty) {
      return 'Mon Profil';
    }
    return widget.playerName!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161926),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gamification : ${_getSafePlayerName()}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            Text(
              'Saison 2024-25',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purpleAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Badges'),
            Tab(text: 'Classement'),
            Tab(text: 'Défis'),
            Tab(text: 'Boutique'),
            Tab(text: 'Barème'),
            Tab(text: 'Alertes'),
          ],
        ),
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentProfile == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }

          if (provider.error != null && provider.currentProfile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchProfile(widget.playerId ?? ''),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              provider.currentProfile != null 
                ? ProfilTab(
                    profile: provider.currentProfile!, 
                    recentActions: provider.recentActions,
                    playerName: _getSafePlayerName(),
                  )
                : const Center(child: Text('Aucun profil trouvé', style: TextStyle(color: Colors.white54))),
              _buildBadgesGrid(),
              const ClassementTab(),
              _buildChallengesTab(),
              _buildShopTab(),
              const BaremeTab(),
              _buildAlertsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        bool isUnlocked = index < 3;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.purpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: isUnlocked ? Colors.purpleAccent : Colors.white10),
              ),
              child: Icon(
                index % 3 == 0 ? Icons.psychology : (index % 3 == 1 ? Icons.bolt : Icons.verified),
                color: isUnlocked ? Colors.purpleAccent : Colors.white24,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Badge $index',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _challengeCard('🧠 Expert Cognitif', 'Compléter 5 tests cette semaine', 0.6, '3/5', 50),
        _challengeCard('⚽ Assiduité', 'Présence à tous les entraînements', 1.0, 'Terminé', 100),
        _challengeCard('🥗 Nutrition Top', 'Loguer ses repas pendant 7 jours', 0.2, '1/7', 30),
      ],
    );
  }

  Widget _challengeCard(String title, String desc, double progress, String label, int reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('+$reward pts', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.greenAccent : Colors.purpleAccent),
                ),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopTab() {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _shopItem('Gilet GPS Pro', '500 pts', Icons.vibration),
        _shopItem('Massage récup', '300 pts', Icons.spa),
        _shopItem('Repas Équipe', '1000 pts', Icons.restaurant),
        _shopItem('Maillot Entraînement', '200 pts', Icons.checkroom),
      ],
    );
  }

  Widget _shopItem(String title, String price, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 40),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text('Échanger', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _alertTile('Nouveau Badge Débloqué !', 'Vous avez obtenu le badge "Expert Cognitif"', 'il y a 2h', Icons.workspace_premium, Colors.amber),
        _alertTile('Points Ajoutés', '+15 pts pour le voyage à Lyon', 'il y a 1j', Icons.add_circle_outline, Colors.greenAccent),
        _alertTile('Nouveau Défi', 'Le coach a lancé un défi hebdomadaire', 'il y a 2j', Icons.flag_outlined, Colors.purpleAccent),
      ],
    );
  }

  Widget _alertTile(String title, String desc, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161926),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        ],
      ),
    );
  }
}
