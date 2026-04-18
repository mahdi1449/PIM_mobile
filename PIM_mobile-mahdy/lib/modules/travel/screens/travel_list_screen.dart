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

  @override
  void initState() {
    super.initState();
    _travels = _api.fetchTravels(widget.clubId);
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: TravelTheme.accentGreen));
        final travels = snapshot.data!;
        final planned = travels.where((t) => t.status == 'planned').toList();
        final activeArr = travels.where((t) => t.status == 'active').toList();
        final completed = travels.where((t) => t.status == 'completed').toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TravelStatBox(label: 'Planifiés', value: '${planned.length}', color: TravelTheme.accentGreen)),
                const SizedBox(width: 12),
                Expanded(child: TravelStatBox(label: 'En cours', value: '${activeArr.length}', color: TravelTheme.accentOrange)),
                const SizedBox(width: 12),
                Expanded(child: TravelStatBox(label: 'Terminés', value: '${completed.length}', color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 32),
            _sectionTitle('Prochain voyage'),
            if (activeArr.isNotEmpty) 
              _buildBigCard(activeArr.first, isActive: true)
            else if (planned.isNotEmpty)
              _buildBigCard(planned.first)
            else
              const Text('Aucun voyage imminent', style: TextStyle(color: Colors.white24)),
            
            const SizedBox(height: 32),
            _sectionTitle('Voyages planifiés'),
            ...planned.skip(activeArr.isEmpty ? 1 : 0).map((t) => _buildSimpleCard(t)),
          ],
        );
      },
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
            ).then((_) => setState(() { _travels = _api.fetchTravels(widget.clubId); })),
          ),
        )
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBigCard(TravelModel travel, {bool isActive = false}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TravelDetailScreen(travelId: travel.id, clubId: widget.clubId))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TravelTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? TravelTheme.accentOrange.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
          boxShadow: [TravelTheme.shadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${travel.destination} · Match Retour', style: TextStyle(color: isActive ? TravelTheme.accentOrange : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isActive ? TravelTheme.accentOrange : TravelTheme.accentGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(travel.statusLabel, style: TextStyle(color: isActive ? TravelTheme.accentOrange : TravelTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${DateFormat('dd MMM').format(travel.departure.at)} · ${travel.departure.modeLabel} · ${travel.hotel.name}', 
              style: const TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                _badge('${travel.participants.players.length} joueurs'),
                const SizedBox(width: 8),
                _badge('${travel.participants.staff.length} staff'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCard(TravelModel travel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildBigCard(travel),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
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
          Text('Terminé', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSeasonStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: const [
        TravelStatBox(label: 'Voyages total', value: '12'),
        TravelStatBox(label: 'Participants total', value: '284'),
        TravelStatBox(label: 'Vols', value: '7', color: TravelTheme.accentOrange),
        TravelStatBox(label: 'Bus / Train', value: '5', color: TravelTheme.accentGreen),
      ],
    );
  }
}
