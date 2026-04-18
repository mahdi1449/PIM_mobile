import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';
import '../widgets/travel_ui_components.dart';
import 'travel_room_screen.dart';
import 'travel_create_screen.dart';

class TravelDetailScreen extends StatefulWidget {
  final String travelId;
  final String clubId;
  const TravelDetailScreen({super.key, required this.travelId, required this.clubId});

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  final TravelApiService _api = TravelApiService();
  late Future<TravelModel> _travel;

  @override
  void initState() {
    super.initState();
    _travel = _api.fetchTravelDetail(widget.travelId, widget.clubId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TravelModel>(
      future: _travel,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: TravelTheme.background, body: Center(child: CircularProgressIndicator(color: TravelTheme.accentGreen)));
        final travel = snapshot.data!;
        
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
                  Tab(text: 'Détail voyage'),
                  Tab(text: 'Participants'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white38),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelCreateScreen(
                          clubId: widget.clubId,
                          travelToEdit: travel,
                        ),
                      ),
                    );
                    setState(() {
                      _travel = _api.fetchTravelDetail(widget.travelId, widget.clubId);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildTimelineView(travel),
                _buildParticipantsView(travel),
              ],
            ),
            bottomNavigationBar: _buildBottomAction(travel),
          ),
        );
      }
    );
  }

  Widget _buildTimelineView(TravelModel travel) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDetailHeader(travel),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: TravelStatBox(label: 'Joueurs', value: '${travel.participants.players.length}')),
            const SizedBox(width: 8),
            Expanded(child: TravelStatBox(label: 'Staff', value: '${travel.participants.staff.length}')),
            const SizedBox(width: 8),
            Expanded(child: TravelStatBox(label: 'Transport', value: travel.departure.modeLabel, color: TravelTheme.accentOrange)),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Chronologie du voyage', style: TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        TravelTimelineNode(
          title: 'Départ — ${travel.departureAirport?.name ?? travel.departure.from}',
          subtitle: '${travel.departure.modeLabel} ${travel.departure.flightNumber ?? ""}',
          time: DateFormat('dd MMM · HH:mm').format(travel.departure.at),
          color: Colors.blueAccent,
        ),
        TravelTimelineNode(
          title: 'Arrivée — Hôtel ${travel.hotel.name}',
          subtitle: 'Check-in ${DateFormat('HH:mm').format(travel.hotel.checkIn)}',
          time: DateFormat('dd MMM · HH:mm').format(travel.hotel.checkIn),
          color: TravelTheme.accentGreen,
        ),
        TravelTimelineNode(
          title: 'Match — Stade de ${travel.destination}',
          subtitle: 'Match Officiel',
          time: DateFormat('dd MMM · HH:mm').format(travel.departure.at.add(const Duration(days: 1))),
          color: Colors.orangeAccent,
        ),
        TravelTimelineNode(
          title: 'Retour — ${travel.arrivalAirport?.name ?? travel.destination}',
          subtitle: 'Transfert Aéroport',
          time: DateFormat('dd MMM · HH:mm').format(travel.travelReturn.at),
          color: Colors.purpleAccent,
          isLast: true,
        ),
        
        const SizedBox(height: 32),
        const Text('Hôtel', style: TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildHotelCard(travel),
      ],
    );
  }

  Widget _buildDetailHeader(TravelModel travel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${travel.destination} · Match Retour', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(travel.departure.at), style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: TravelTheme.accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(travel.statusLabel, style: const TextStyle(color: TravelTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildHotelCard(TravelModel travel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TravelTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(travel.hotel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(travel.hotel.address, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniBadge('${travel.hotel.doubleRooms} doubles'),
              const SizedBox(width: 8),
              _miniBadge('${travel.hotel.singleRooms} singles'),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    );
  }

  Widget _buildParticipantsView(TravelModel travel) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Participants', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('${travel.destination} · Match Retour · ${DateFormat('dd MMM').format(travel.departure.at)}', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 32),
        _subHeader('Joueurs (${travel.participants.players.length})'),
        ...travel.participants.players.map((p) => _participantTile(p, travel)),
        const SizedBox(height: 32),
        _subHeader('Staff (${travel.participants.staff.length})'),
        ...travel.participants.staff.map((s) => _participantTile(s, travel, isStaff: true)),
      ],
    );
  }

  Widget _subHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _participantTile(ParticipantInfo p, TravelModel travel, {bool isStaff = false}) {
    // Simuler un numéro de chambre pour le design
    String roomNo = '104'; 
    try {
      final room = travel.hotel.rooms.firstWhere((r) => r.occupant1Id == p.id || r.occupant2Id == p.id);
      roomNo = room.roomNumber;
    } catch (e) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isStaff ? Colors.orangeAccent : TravelTheme.accentGreen).withOpacity(0.2),
            child: Text(p.initials, style: TextStyle(color: isStaff ? Colors.orangeAccent : TravelTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Chambre $roomNo', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(p.position ?? (isStaff ? 'Staff' : 'Joueur'), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(TravelModel travel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TravelTheme.background, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TravelRoomScreen(travel: travel, clubId: widget.clubId))),
        icon: const Icon(Icons.hotel),
        label: const Text('GÉRER LES CHAMBRES'),
        style: ElevatedButton.styleFrom(
          backgroundColor: TravelTheme.accentBlue,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TravelTheme.cardBg,
        title: const Text('Supprimer le voyage', style: TextStyle(color: Colors.white)),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce voyage ? Cette action est irréversible.', style: TextStyle(color: TravelTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUPPRIMER', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteTravel(widget.travelId, widget.clubId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }
}
