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
      if (widget.playerId != null) {
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
              widget.playerName != null 
                  ? 'Gamification : ${widget.playerName}'
                  : 'Récompenses & Gamification',
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
            return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              provider.currentProfile != null 
                ? ProfilTab(
                    profile: provider.currentProfile!, 
                    recentActions: provider.recentActions,
                    playerName: widget.playerName,
                  )
                : const Center(child: Text('Aucun profil trouvé', style: TextStyle(color: Colors.white54))),
              _buildPlaceholderTab('🎖️ Badges'),
              const ClassementTab(),
              _buildPlaceholderTab('🎯 Défis'),
              _buildPlaceholderTab('🛒 Boutique'),
              const BaremeTab(),
              _buildPlaceholderTab('🔔 Alertes'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'En cours de développement...',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
