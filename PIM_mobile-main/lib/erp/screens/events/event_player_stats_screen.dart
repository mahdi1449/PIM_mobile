import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import 'team_stats_summary_screen.dart';

class EventPlayerStatsScreen extends StatefulWidget {
  final String eventId;
  const EventPlayerStatsScreen({super.key, required this.eventId});

  @override
  State<EventPlayerStatsScreen> createState() => _EventPlayerStatsScreenState();
}

class _EventPlayerStatsScreenState extends State<EventPlayerStatsScreen> {
  bool _loading = false;
  final Map<String, PlayerStatEntry> _statsMap = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    await provider.fetchParticipants(widget.eventId);
    _loadParticipants();
    if (mounted) setState(() => _loading = false);
  }

  void _loadParticipants() {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    _statsMap.clear();
    for (var p in provider.participants) {
      if (p.status == 'confirmed' || p.status == 'present') {
        _statsMap[p.participantId] = PlayerStatEntry(
          id: p.id,
          participantId: p.participantId,
          name: p.name,
          position: p.role, 
          played: p.played,
          isStarter: p.isStarter,
          rating: p.rating ?? 7.0,
          goals: p.goals,
          assists: p.assists,
          minutes: p.minutesPlayed > 0 ? p.minutesPlayed : (p.isStarter ? 90 : 0),
          shotsOnTarget: p.shotsOnTarget,
          keyPasses: p.keyPasses,
          tackles: p.tackles,
          interceptions: p.interceptions,
          clearances: p.clearances,
          saves: p.saves,
          goalsConceded: p.goalsConceded,
          penaltiesSaved: p.penaltiesSaved,
          yellowCard: p.yellowCard,
          redCard: p.redCard,
          cardMinute: p.cardMinute,
          distanceCovered: p.distanceCovered,
          topSpeed: p.topSpeed,
          sprints: p.sprints,
          privateNote: p.privateNote,
          publicNote: p.publicNote,
        );
      }
    }
  }

  Future<void> _saveStats() async {
    setState(() => _loading = true);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    final statsList = _statsMap.values.map((s) => s.toJson()).toList();
    final success = await provider.saveBulkPlayerStats(widget.eventId, statsList);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statistiques enregistrées !'), backgroundColor: OdinTheme.accentGreen),
      );
      
      // Navigate to summary instead of just popping
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TeamStatsSummaryScreen(eventId: widget.eventId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Erreur'), backgroundColor: OdinTheme.accentRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmedPlayers = _statsMap.values.toList();

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('STATS INDIVIDUELLES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saveStats,
              child: const Text('ENREGISTRER', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : confirmedPlayers.isEmpty
              ? const Center(child: Text('Aucun joueur à évaluer', style: TextStyle(color: OdinTheme.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: confirmedPlayers.length,
                  itemBuilder: (context, index) {
                    final entry = confirmedPlayers[index];
                    return _buildPlayerStatCard(entry);
                  },
                ),
    );
  }

  Widget _buildPlayerStatCard(PlayerStatEntry entry) {
    final isGK = entry.position.toUpperCase() == 'GK' || entry.position.toUpperCase() == 'GARDIEN';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: OdinTheme.glassCard,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.03),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: OdinTheme.primaryBlue.withOpacity(0.2),
                  child: Text(entry.name[0], style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                      Text(entry.position, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _statusToggle('JOUÉ', entry.played, (v) => setState(() => entry.played = v)),
              ],
            ),
          ),

          if (entry.played) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TEMPS DE JEU
                  _sectionHeader(Icons.timer_outlined, 'TEMPS DE JEU'),
                  Row(
                    children: [
                      Expanded(
                        child: _choiceChip<bool>(
                          label: entry.isStarter ? 'TITULAIRE' : 'REMPLAÇANT',
                          value: entry.isStarter,
                          onSelected: (v) => setState(() => entry.isStarter = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _minutesInput(entry),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. OFFENSIF
                  _sectionHeader(Icons.bolt_rounded, 'OFFENSIF'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _statCounterSmall('BUTS', entry.goals, (v) => setState(() => entry.goals = v)),
                      _statCounterSmall('PASSES D.', entry.assists, (v) => setState(() => entry.assists = v)),
                      _statCounterSmall('TIRS CADRÉS', entry.shotsOnTarget, (v) => setState(() => entry.shotsOnTarget = v)),
                      _statCounterSmall('PASSES CLÉS', entry.keyPasses, (v) => setState(() => entry.keyPasses = v)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. DÉFENSIF (Or GK)
                  if (isGK) ...[
                    _sectionHeader(Icons.pan_tool_rounded, 'GARDIEN'),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _statCounterSmall('ARRÊTS', entry.saves, (v) => setState(() => entry.saves = v)),
                        _statCounterSmall('BUTS ENC.', entry.goalsConceded, (v) => setState(() => entry.goalsConceded = v)),
                        _statCounterSmall('PENALTY ARR.', entry.penaltiesSaved, (v) => setState(() => entry.penaltiesSaved = v)),
                      ],
                    ),
                  ] else ...[
                    _sectionHeader(Icons.security_rounded, 'DÉFENSIF'),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _statCounterSmall('TACKLES', entry.tackles, (v) => setState(() => entry.tackles = v)),
                        _statCounterSmall('INTERCEPT.', entry.interceptions, (v) => setState(() => entry.interceptions = v)),
                        _statCounterSmall('DÉGAGEMENTS', entry.clearances, (v) => setState(() => entry.clearances = v)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 4. DISCIPLINE & PHYSIQUE
                  _sectionHeader(Icons.analytics_outlined, 'DISCIPLINE & PHYSIQUE'),
                  Row(
                    children: [
                      _cardToggle(entry),
                      const SizedBox(width: 12),
                      Expanded(child: _statInput('KM', entry.distanceCovered, (v) => entry.distanceCovered = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _statInput('KM/H', entry.topSpeed, (v) => entry.topSpeed = v)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. ÉVALUATION
                  _sectionHeader(Icons.star_rounded, 'ÉVALUATION COACH'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NOTE / 10', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(entry.rating.toStringAsFixed(1), style: const TextStyle(color: OdinTheme.accentOrange, fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: entry.rating,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    activeColor: OdinTheme.accentOrange,
                    onChanged: (v) => setState(() => entry.rating = v),
                  ),
                  const SizedBox(height: 12),
                  _noteInput('NOTE PRIVÉE (COACH)', entry.privateNote, (v) => entry.privateNote = v),
                  const SizedBox(height: 8),
                  _noteInput('MESSAGE AU JOUEUR', entry.publicNote, (v) => entry.publicNote = v),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: OdinTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _statusToggle(String label, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? OdinTheme.accentGreen.withOpacity(0.1) : OdinTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? OdinTheme.accentGreen.withOpacity(0.3) : OdinTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(value ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: value ? OdinTheme.accentGreen : OdinTheme.textTertiary),
            const SizedBox(width: 6),
            Text(value ? 'OUI' : 'NON', style: TextStyle(color: value ? OdinTheme.accentGreen : OdinTheme.textTertiary, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip<T>({required String label, required bool value, required Function(bool) onSelected}) {
    return InkWell(
      onTap: () => onSelected(!value),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: OdinTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OdinTheme.cardBorder),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _minutesInput(PlayerStatEntry entry) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: OdinTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.timer_outlined, size: 14, color: OdinTheme.textTertiary),
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: 'Min.', hintStyle: TextStyle(color: OdinTheme.textTertiary, fontSize: 10), border: InputBorder.none),
              onChanged: (v) => entry.minutes = int.tryParse(v) ?? 0,
              controller: TextEditingController(text: entry.minutes.toString())..selection = TextSelection.fromPosition(TextPosition(offset: entry.minutes.toString().length)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Text('min', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _statCounterSmall(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: OdinTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: OdinTheme.cardBorder)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.bold))),
          Row(
            children: [
              _tinyCircleBtn(Icons.remove, () { if (value > 0) onChanged(value - 1); }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              _tinyCircleBtn(Icons.add, () => onChanged(value + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }

  Widget _cardToggle(PlayerStatEntry entry) {
    final color = entry.redCard ? OdinTheme.accentRed : (entry.yellowCard ? OdinTheme.accentOrange : OdinTheme.textTertiary);
    final label = entry.redCard ? 'ROUGE' : (entry.yellowCard ? 'JAUNE' : 'AUCUN');
    
    return InkWell(
      onTap: () {
        setState(() {
          if (!entry.yellowCard && !entry.redCard) entry.yellowCard = true;
          else if (entry.yellowCard) { entry.yellowCard = false; entry.redCard = true; }
          else { entry.redCard = false; }
        });
      },
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(color: OdinTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CARTON', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 8, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _statInput(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(color: OdinTheme.surface, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
            controller: TextEditingController(text: value.toString())..selection = TextSelection.fromPosition(TextPosition(offset: value.toString().length)),
          ),
        ),
      ],
    );
  }

  Widget _noteInput(String label, String? value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          decoration: InputDecoration(
            filled: true,
            fillColor: OdinTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(10),
          ),
          onChanged: onChanged,
          controller: TextEditingController(text: value ?? ''),
        ),
      ],
    );
  }
}

class PlayerStatEntry {
  final String? id; // Participant record ID
  final String participantId;
  final String name;
  final String position;

  bool played;
  bool isStarter;
  double rating;
  int goals;
  int assists;
  int minutes;
  int? minuteIn;
  int? minuteOut;
  int shotsOnTarget;
  int keyPasses;
  int tackles;
  int interceptions;
  int clearances;
  int saves;
  int goalsConceded;
  int penaltiesSaved;
  bool yellowCard;
  bool redCard;
  int? cardMinute;
  double distanceCovered;
  double topSpeed;
  int sprints;
  String? privateNote;
  String? publicNote;

  PlayerStatEntry({
    this.id,
    required this.participantId,
    required this.name,
    this.position = 'Joueur',
    this.played = true,
    this.isStarter = true,
    this.rating = 7.0,
    this.goals = 0,
    this.assists = 0,
    this.minutes = 90,
    this.minuteIn,
    this.minuteOut,
    this.shotsOnTarget = 0,
    this.keyPasses = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.saves = 0,
    this.goalsConceded = 0,
    this.penaltiesSaved = 0,
    this.yellowCard = false,
    this.redCard = false,
    this.cardMinute,
    this.distanceCovered = 0.0,
    this.topSpeed = 0.0,
    this.sprints = 0,
    this.privateNote,
    this.publicNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'participantId': participantId,
    'played': played,
    'isStarter': isStarter,
    'rating': double.parse(rating.toStringAsFixed(1)),
    'goals': goals,
    'assists': assists,
    'minutesPlayed': minutes,
    'minuteIn': minuteIn,
    'minuteOut': minuteOut,
    'shotsOnTarget': shotsOnTarget,
    'keyPasses': keyPasses,
    'tackles': tackles,
    'interceptions': interceptions,
    'clearances': clearances,
    'saves': saves,
    'goalsConceded': goalsConceded,
    'penaltiesSaved': penaltiesSaved,
    'yellowCard': yellowCard,
    'redCard': redCard,
    'cardMinute': cardMinute,
    'distanceCovered': distanceCovered,
    'topSpeed': topSpeed,
    'sprints': sprints,
    'privateNote': privateNote,
    'publicNote': publicNote,
  };
}
