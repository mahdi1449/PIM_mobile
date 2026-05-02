import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';
import '../widgets/travel_ui_components.dart';
import 'travel_create_screen.dart';
import 'travel_detail_screen.dart';

class TravelListScreen extends StatefulWidget {
  final String clubId;
  const TravelListScreen({super.key, required this.clubId});

  @override
  State<TravelListScreen> createState() => _TravelListScreenState();
}

class _TravelListScreenState extends State<TravelListScreen> {
  final TravelApiService _api = TravelApiService();
  late Future<List<TravelModel>> _travels;
  late Future<List<dynamic>> _stats;
  String _statusFilter = 'all'; // all, planned, active, completed

  @override
  void initState() {
    super.initState();
    _travels = _api.fetchTravels(widget.clubId);
    _stats = _api.fetchTravelStats(widget.clubId);
  }

  void _refreshData() {
    setState(() {
      _travels = _api.fetchTravels(widget.clubId);
      _stats = _api.fetchTravelStats(widget.clubId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TravelTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: TravelTheme.accentGreen,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelColor: Colors.white24,
            tabs: [
              Tab(text: 'Liste des voyages'),
              Tab(text: 'Historique'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white38),
              onPressed: () {},
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildMainDashboard(),
            _buildHistoryView(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return FutureBuilder<List<TravelModel>>(
      future: _travels,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
                TextButton(onPressed: _refreshData, child: const Text('RÉESSAYER')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: TravelTheme.accentGreen));
        
        final allTravels = snapshot.data!;
        final plannedCount = allTravels.where((t) => t.status == 'planned').length;
        final activeCount = allTravels.where((t) => t.status == 'active').length;
        final completedCount = allTravels.where((t) => t.status == 'completed').length;

        // Liste filtrée pour l'affichage
        List<TravelModel> filteredList = List.from(allTravels);
        if (_statusFilter != 'all') {
          filteredList = allTravels.where((t) => t.status == _statusFilter).toList();
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilterBar(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TravelStatBox(label: 'Planifiés', value: '$plannedCount', color: TravelTheme.accentGreen)),
                const SizedBox(width: 12),
                Expanded(child: TravelStatBox(label: 'En cours', value: '$activeCount', color: TravelTheme.accentOrange)),
                const SizedBox(width: 12),
                Expanded(child: TravelStatBox(label: 'Terminés', value: '$completedCount', color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 32),
            
            if (_statusFilter == 'all') ...[
              _buildSectionedView(allTravels),
            ] else ...[
              _buildFilteredListView(filteredList),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionedView(List<TravelModel> travels) {
    final active = travels.where((t) => t.status == 'active').toList();
    final planned = travels.where((t) => t.status == 'planned').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Prochain voyage'),
        if (active.isNotEmpty) 
          _buildBigCard(active.first, isActive: true)
        else if (planned.isNotEmpty)
          _buildBigCard(planned.first)
        else
          const Text('Aucun voyage imminent', style: TextStyle(color: Colors.white24)),
        
        if (planned.isNotEmpty) ...[
          const SizedBox(height: 32),
          _sectionTitle('Voyages planifiés'),
          ...planned.skip(active.isEmpty ? 1 : 0).map((t) => _buildSimpleCard(t)),
        ],
      ],
    );
  }

  Widget _buildFilteredListView(List<TravelModel> filteredList) {
    String title = 'Résultats';
    if (_statusFilter == 'planned') title = 'Voyages planifiés';
    if (_statusFilter == 'active') title = 'Voyages en cours';
    if (_statusFilter == 'completed') title = 'Voyages terminés';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        if (filteredList.isEmpty)
          const Text('Aucun voyage trouvé pour ce filtre', style: TextStyle(color: Colors.white24))
        else
          ...filteredList.map((t) => _buildSimpleCard(t)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Travel Manager', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('ES Tunis · Saison 2024-25', style: TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
          ],
        ),
        Container(
          decoration: BoxDecoration(color: TravelTheme.accentBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TravelCreateScreen(clubId: widget.clubId)),
            ).then((_) => _refreshData()),
          ),
        )
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'Tous'},
      {'id': 'planned', 'label': 'Planifiés'},
      {'id': 'active', 'label': 'En cours'},
      {'id': 'completed', 'label': 'Terminés'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _statusFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12)),
              selected: isSelected,
              onSelected: (val) => setState(() => _statusFilter = f['id']!),
              backgroundColor: TravelTheme.cardBg,
              selectedColor: TravelTheme.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? TravelTheme.accentBlue : Colors.white.withOpacity(0.05)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBigCard(TravelModel travel, {bool isActive = false}) {
    return Dismissible(
      key: Key(travel.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) => _confirmDelete(context, travel),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TravelDetailScreen(travelId: travel.id, clubId: widget.clubId))
        ).then((_) => _refreshData()),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TravelTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? TravelTheme.accentOrange : Colors.white.withOpacity(0.05),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [TravelTheme.shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${travel.destination} · Match Retour', 
                          style: TextStyle(color: isActive ? TravelTheme.accentOrange : Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(travel.departure.modeIcon, size: 12, color: TravelTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(travel.departure.modeLabel, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCountdownBadge(travel),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _badge('${travel.participants.players.length} joueurs', Icons.people_outline),
                  const SizedBox(width: 8),
                  _badge('${travel.hotel.name}', Icons.hotel_outlined, isIata: travel.departure.mode == 'flight' && (travel.arrivalAirport?.code != null)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(TravelModel travel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: travel.countdownColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        travel.countdownLabel,
        style: TextStyle(color: travel.countdownColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSimpleCard(TravelModel travel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildBigCard(travel),
    );
  }

  Widget _badge(String text, IconData icon, {bool isIata = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, TravelModel travel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TravelTheme.cardBg,
        title: const Text('Supprimer ce voyage ?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Action irréversible. Toutes les données logistiques seront perdues.', style: TextStyle(color: TravelTheme.textMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteTravel(travel.id, widget.clubId);
        _refreshData();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        return false;
      }
    }
    return false;
  }

  Widget _buildHistoryView() {
    return FutureBuilder<List<TravelModel>>(
      future: _travels,
      builder: (context, snapshot) {
        final completed = (snapshot.data ?? []).where((t) => t.status == 'completed').toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Historique', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Voyages terminés · Saison', style: TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 32),
            _sectionTitle('Derniers voyages'),
            ...completed.map((t) => _buildHistoryItem(t)),
            const SizedBox(height: 32),
            _sectionTitle('Statistiques saison'),
            _buildSeasonStats(),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(TravelModel travel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TravelDetailScreen(travelId: travel.id, clubId: widget.clubId))
        ).then((_) => _refreshData()),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.location_on, color: TravelTheme.accentGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(travel.destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${DateFormat('dd MMM').format(travel.departure.at)} · Championnat · ${travel.departure.modeLabel}', 
                    style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 16),
            const SizedBox(width: 8),
            Text('Terminé', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonStats() {
    return FutureBuilder<List<dynamic>>(
      future: _stats,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? [];
        int total = 0;
        int completed = 0;
        int planned = 0;
        int active = 0;
        int flights = 0;
        int busTrain = 0;

        for (var s in stats) {
          int count = s['count'] ?? 0;
          if (['completed', 'planned', 'active', 'cancelled'].contains(s['_id'])) {
            total += count;
            if (s['_id'] == 'completed') completed = count;
            if (s['_id'] == 'planned') planned = count;
            if (s['_id'] == 'active') active = count;
          } else {
            if (s['_id'] == 'flight') flights += count;
            if (s['_id'] == 'bus' || s['_id'] == 'train') busTrain += count;
          }
        }

        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                TravelStatBox(label: 'Total voyages', value: '$total'),
                TravelStatBox(label: 'Terminés', value: '$completed', color: TravelTheme.accentGreen),
                TravelStatBox(label: 'Planifiés', value: '$planned', color: TravelTheme.accentBlue),
                TravelStatBox(label: 'En cours', value: '$active', color: TravelTheme.accentOrange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TravelStatBox(label: 'Vols', value: '$flights')),
                const SizedBox(width: 12),
                Expanded(child: TravelStatBox(label: 'Bus/Train', value: '$busTrain')),
              ],
            ),
          ],
        );
      }
    );
  }
}
