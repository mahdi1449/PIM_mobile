import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification_models.dart';
import '../widgets/profil_tab.dart';
import '../widgets/classement_tab.dart';
import '../widgets/bareme_tab.dart';
import '../providers/gamification_provider.dart';
import '../../../erp/providers/auth_provider.dart';

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role?.toUpperCase() ?? '';
      final userType = authProvider.user?.userType?.toUpperCase() ?? '';
      final fullName = authProvider.user?.fullName.toUpperCase() ?? '';
      final userId = authProvider.user?.id;

      final isAdmin = role.contains('ADMIN') || role.contains('MANAGER') || role.contains('COACH') || role.contains('STAFF') ||
                      userType.contains('ADMIN') || userType.contains('MANAGER') || userType.contains('COACH') ||
                      fullName.contains('ADMIN');

      if (widget.playerId != null && widget.playerId!.isNotEmpty) {
        context.read<GamificationProvider>().fetchProfile(widget.playerId!);
      } else if (userId != null) {
        context.read<GamificationProvider>().fetchProfile(userId);
      }
      
      context.read<GamificationProvider>().fetchLeaderboard();

      // Charger les achats globaux si l'utilisateur est un Admin/Staff
      if (isAdmin) {
        context.read<GamificationProvider>().fetchAdminPurchases();
      }
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
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.user?.role?.toUpperCase() ?? '';
    final userType = auth.user?.userType?.toUpperCase() ?? '';
    final fullName = auth.user?.fullName.toUpperCase() ?? widget.playerName?.toUpperCase() ?? '';
    
    final isAdmin = role.contains('ADMIN') || role.contains('MANAGER') || role.contains('COACH') || role.contains('STAFF') ||
                    userType.contains('ADMIN') || userType.contains('MANAGER') || userType.contains('COACH') ||
                    fullName.contains('ADMIN');

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSafePlayerName(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 12),
                const SizedBox(width: 4),
                Text(
                  'SAISON 2024-25 • PERFORMANCE PRO',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white70),
            onPressed: () => _tabController.animateTo(6),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Color(0xFF6366F1)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                const Tab(text: 'Profil'),
                const Tab(text: 'Badges'),
                const Tab(text: 'Classement'),
                const Tab(text: 'Défis'),
                const Tab(text: 'Boutique'),
                const Tab(text: 'Barème'),
                Tab(text: isAdmin ? 'Journal Ventes' : 'Alertes'),
              ],
            ),
          ),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.fetchProfile(widget.playerId ?? ''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('RÉESSAYER'),
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
              _buildAlertsTab(isAdmin),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid() {
    final List<Map<String, dynamic>> badgeTypes = [
      {'title': 'Cerveau d\'Acier', 'icon': Icons.psychology_rounded, 'color': Colors.blueAccent},
      {'title': 'Éclair de Génie', 'icon': Icons.bolt_rounded, 'color': Colors.amberAccent},
      {'title': 'Mur Infranchissable', 'icon': Icons.shield_rounded, 'color': Colors.redAccent},
      {'title': 'Vision de Jeu', 'icon': Icons.visibility_rounded, 'color': Colors.greenAccent},
      {'title': 'Endurance Élite', 'icon': Icons.timer_rounded, 'color': Colors.orangeAccent},
      {'title': 'Maître Tacticien', 'icon': Icons.grid_view_rounded, 'color': Colors.purpleAccent},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        bool isUnlocked = index < 4;
        final type = badgeTypes[index % badgeTypes.length];
        final Color color = isUnlocked ? type['color'] : Colors.white10;

        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                  boxShadow: isUnlocked ? [
                    BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: -5)
                  ] : null,
                ),
                child: Center(
                  child: Icon(
                    type['icon'],
                    color: isUnlocked ? color : Colors.white10,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isUnlocked ? type['title'] : 'Verrouillé',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white24,
                fontSize: 10,
                fontWeight: isUnlocked ? FontWeight.w900 : FontWeight.normal,
                letterSpacing: 0.5,
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
        _challengeCard('🧠 Expert Cognitif', 'Compléter 5 tests cette semaine', 0.6, '3/5', 50, Colors.blueAccent),
        _challengeCard('⚽ Assiduité', 'Présence à tous les entraînements', 1.0, 'Terminé', 100, Colors.greenAccent),
        _challengeCard('🥗 Nutrition Top', 'Loguer ses repas pendant 7 jours', 0.2, '1/7', 30, Colors.orangeAccent),
        _challengeCard('⚡ Récupération', 'Dormir 8h pendant 3 nuits consécutives', 0.0, '0/3', 40, Colors.purpleAccent),
      ],
    );
  }

  Widget _challengeCard(String title, String desc, double progress, String label, int reward, Color accentColor) {
    bool isCompleted = progress >= 1.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCompleted ? accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Text('+$reward PTS', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? accentColor : Colors.purpleAccent),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label, 
                style: TextStyle(color: isCompleted ? accentColor : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
              ),
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
      childAspectRatio: 0.75, // Ajusté légèrement pour laisser de la place au texte plus long
      children: [
        _shopItem('Pack Accessoires', '150 pts', Icons.backpack, Colors.tealAccent),
        _shopItem('Maillot Élite', '200 pts', Icons.checkroom, Colors.blueAccent),
        _shopItem('Sac Élite', '300 pts', Icons.business_center, Colors.indigoAccent),
        _shopItem('Massage récup', '300 pts', Icons.spa, Colors.greenAccent),
        _shopItem('Gilet GPS Pro', '500 pts', Icons.vibration, Colors.cyanAccent),
        _shopItem('Chaussures Pro', '800 pts', Icons.directions_run, Colors.redAccent),
        _shopItem('Repas Équipe', '1000 pts', Icons.restaurant, Colors.orangeAccent),
      ],
    );
  }

  Widget _shopItem(String title, String price, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E2130), const Color(0xFF121421)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showExchangeDialog(context, title, price),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('ÉCHANGER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _showExchangeDialog(BuildContext context, String item, String priceStr) {
    int price = int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final provider = Provider.of<GamificationProvider>(context, listen: false);
    final totalPoints = provider.currentProfile?.totalPoints ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer l\'échange', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous échanger $priceStr contre "$item" ?\n\nVous avez actuellement $totalPoints pts.', 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (totalPoints >= price) {
                final userId = provider.currentProfile?.userId;
                
                if (userId != null && userId.isNotEmpty) {
                  // Fermer le dialogue AVANT de commencer l'opération asynchrone
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  final result = await provider.redeemReward(userId, item, price);
                  
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        content: Text('Achat réussi ! Votre coach validera "$item" prochainement.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        content: Text(result['message'] ?? 'Erreur lors de l\'achat'),
                      ),
                    );
                  }
                }
              } else {
                // Fonds insuffisants - on ferme quand même le dialogue
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Fonds insuffisants. Il vous manque ${price - totalPoints} pts.')),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: const Text('CONFIRMER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(bool isAdmin) {
    return Consumer<GamificationProvider>(
      builder: (context, provider, child) {
        if (isAdmin) {
          if (provider.adminPurchases.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Aucun achat enregistré', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.adminPurchases.length,
            itemBuilder: (context, index) {
              final purchase = provider.adminPurchases[index];
              final String userName = purchase['userName'] ?? 'Joueur Inconnu';
              final String item = purchase['description']?.replaceAll('Achat de : ', '') ?? 'Article';
              final int points = (purchase['points'] as num?)?.toInt()?.abs() ?? 0;
              final String date = purchase['createdAt'] != null 
                ? _formatTimeAgo(DateTime.parse(purchase['createdAt'])) 
                : 'RÉCEMMENT';

              return InkWell(
                onTap: () {
                  if (purchase['userId'] != null) {
                    _showPlayerPurchases(context, purchase['userId'], userName, provider.adminPurchases);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                      child: Text(userName.substring(0, 1), style: const TextStyle(color: Colors.purpleAccent)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('A acheté : $item', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('-$points PTS', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        Text(date, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              );
            },
          );
        }

        // Vue Joueur Classique
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _alertTile('Nouveau Badge Débloqué !', 'Vous avez obtenu le badge "Cerveau d\'Acier"', 'IL Y A 2H', Icons.workspace_premium, Colors.amber),
            _alertTile('Points Ajoutés', '+15 pts pour le voyage à Lyon', 'IL Y A 1J', Icons.add_circle_outline, Colors.greenAccent),
            _alertTile('Nouveau Défi', 'Le coach a lancé un défi hebdomadaire', 'IL Y A 2J', Icons.flag_outlined, Colors.purpleAccent),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return 'IL Y A ${duration.inDays}J';
    if (duration.inHours > 0) return 'IL Y A ${duration.inHours}H';
    if (duration.inMinutes > 0) return 'IL Y A ${duration.inMinutes}M';
    return 'À L\'INSTANT';
  }

  String _formatDateDetailed(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPlayerPurchases(BuildContext context, String userId, String userName, List<dynamic> allPurchases) {
    final playerPurchases = allPurchases.where((p) => p['userId'] == userId).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1E2130),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                    radius: 24,
                    child: Text(userName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historique des achats', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${playerPurchases.length} achat(s)',
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: playerPurchases.length,
                itemBuilder: (context, index) {
                  final purchase = playerPurchases[index];
                  final String item = purchase['description']?.replaceAll('Achat de : ', '') ?? 'Article';
                  final int points = (purchase['points'] as num?)?.toInt()?.abs() ?? 0;
                  final String date = purchase['createdAt'] != null 
                    ? _formatDateDetailed(DateTime.parse(purchase['createdAt'])) 
                    : 'Récemment';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.purpleAccent, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white38, size: 12),
                                  const SizedBox(width: 4),
                                  Text(date, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-$points PTS', 
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(String title, String desc, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
