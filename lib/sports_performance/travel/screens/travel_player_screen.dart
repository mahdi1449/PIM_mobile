import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';
import '../widgets/travel_ui_components.dart';

class TravelPlayerScreen extends StatefulWidget {
  final String playerId;
  final String clubId;
  const TravelPlayerScreen({super.key, required this.playerId, required this.clubId});

  @override
  State<TravelPlayerScreen> createState() => _TravelPlayerScreenState();
}

class _TravelPlayerScreenState extends State<TravelPlayerScreen> {
  final TravelApiService _api = TravelApiService();
  late Future<List<TravelModel>> _travels;

  @override
  void initState() {
    super.initState();
    _travels = _api.fetchPlayerTravels(widget.clubId, widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('MON VOYAGE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<TravelModel>>(
        future: _travels,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: TravelTheme.accentGreen));
          final travels = snapshot.data!;
          if (travels.isEmpty) return const Center(child: Text('Aucun voyage prévu', style: TextStyle(color: Colors.white24)));
          
          final nextOne = travels.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildPlayerHeader(),
              const SizedBox(height: 24),
              _buildCountdown(),
              const SizedBox(height: 24),
              _sectionTitle('Mon prochain voyage'),
              _buildNextTravelCard(nextOne),
              const SizedBox(height: 24),
              _sectionTitle('Ma chambre'),
              _buildRoomCard(nextOne),
              const SizedBox(height: 24),
              _sectionTitle('Informations pratiques'),
              _buildPracticalInfo(nextOne),
              const SizedBox(height: 32),
              _sectionTitle('Mes voyages passés'),
              ...travels.skip(1).map((t) => _buildPastTravelItem(t)),
              const SizedBox(height: 32),
              _sectionTitle('Mes statistiques voyage'),
              _buildPersonalStats(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: TravelTheme.accentGreen.withOpacity(0.1),
          child: const Text('KM', style: TextStyle(color: TravelTheme.accentGreen, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Karim Mellouki', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Milieu offensif · ES Tunis', style: TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: TravelTheme.accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: TravelTheme.accentOrange.withOpacity(0.2))),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: TravelTheme.accentOrange, size: 14),
          const SizedBox(width: 8),
          Text('Prochain départ dans 5 jours', style: TextStyle(color: TravelTheme.accentOrange, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNextTravelCard(TravelModel t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TravelTheme.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: TravelTheme.accentOrange.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${t.destination} · Coupe', style: const TextStyle(color: TravelTheme.accentOrange, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${DateFormat('dd MMMM').format(t.departure.at)} · Départ ${DateFormat('HH:mm').format(t.departure.at)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${t.departure.modeLabel} ${t.departure.flightNumber ?? ""} · ${t.departureAirport?.name ?? "Tunis Carthage"}', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(TravelModel t) {
    // Mocking room data for player Karim Mellouki
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TravelTheme.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chambre 101 — Double', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Avec Youcef Brahimi', style: TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(backgroundColor: TravelTheme.accentBlue.withOpacity(0.2), radius: 18, child: const Text('YB', style: TextStyle(color: TravelTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildPracticalInfo(TravelModel t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TravelTheme.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        children: [
          _infoLine('Hôtel', t.hotel.name),
          _infoLine('Check-in', DateFormat('dd MMM · HH:mm').format(t.hotel.checkIn)),
          _infoLine('Check-out', DateFormat('dd MMM · HH:mm').format(t.hotel.checkOut)),
          _infoLine('Retour vol', t.travelReturn.flightNumber ?? 'TU225 · 09h00'),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPastTravelItem(TravelModel t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: TravelTheme.accentGreen, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.destination} · Championnat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('dd MMMM').format(t.departure.at), style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          _statusBadge('Titulaire', TravelTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPersonalStats() {
    return Row(
      children: [
        Expanded(child: TravelStatBox(label: 'Voyages total', value: '11')),
        const SizedBox(width: 12),
        Expanded(child: TravelStatBox(label: 'Titulaire', value: '9', color: TravelTheme.accentGreen)),
      ],
    );
  }
}
