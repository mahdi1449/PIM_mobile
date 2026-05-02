import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';

class MatchSheetScreen extends StatefulWidget {
  final String eventId;
  const MatchSheetScreen({super.key, required this.eventId});

  @override
  State<MatchSheetScreen> createState() => _MatchSheetScreenState();
}

class _MatchSheetScreenState extends State<MatchSheetScreen> {
  String _formation = '4-4-2';
  final Map<int, String?> _lineup = {}; // Position Index -> Player ID
  bool _saving = false;

  final Map<String, List<Offset>> _formationsConfig = {
    '4-4-2': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.7), const Offset(0.38, 0.73), const Offset(0.62, 0.73), const Offset(0.85, 0.7), // DEF
      const Offset(0.15, 0.45), const Offset(0.38, 0.48), const Offset(0.62, 0.48), const Offset(0.85, 0.45), // MID
      const Offset(0.35, 0.2), const Offset(0.65, 0.2), // FWD
    ],
    '4-3-3': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.7), const Offset(0.38, 0.73), const Offset(0.62, 0.73), const Offset(0.85, 0.7), // DEF
      const Offset(0.25, 0.48), const Offset(0.5, 0.52), const Offset(0.75, 0.48), // MID
      const Offset(0.2, 0.25), const Offset(0.5, 0.18), const Offset(0.8, 0.25), // FWD
    ],
    '3-5-2': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.25, 0.73), const Offset(0.5, 0.75), const Offset(0.75, 0.73), // DEF
      const Offset(0.1, 0.5), const Offset(0.3, 0.5), const Offset(0.5, 0.52), const Offset(0.7, 0.5), const Offset(0.9, 0.5), // MID
      const Offset(0.35, 0.25), const Offset(0.65, 0.25), // FWD
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<EventsProvider>(context, listen: false);
      await provider.fetchParticipants(widget.eventId);
      await provider.fetchMatchSheet(widget.eventId);
      
      // Load saved lineup
      if (mounted) {
        final sheet = provider.matchSheet?['matchSheet'];
        if (sheet != null) {
          setState(() {
            _formation = sheet['formation'] ?? '4-4-2';
            final starters = sheet['starters'] as List?;
            if (starters != null) {
              for (var s in starters) {
                final pId = s['playerId'];
                final posLabel = s['position'];
                if (pId != null && posLabel != null) {
                  // Reconvert string position to int index
                  final idx = int.tryParse(posLabel.toString());
                  if (idx != null) {
                    _lineup[idx] = pId.toString();
                  }
                }
              }
            }
          });
        }
      }
    });
  }

  void _saveLineup() async {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    // Prepare starters DTO
    final List<Map<String, dynamic>> starters = [];
    _lineup.forEach((idx, pId) {
      if (pId != null) {
        // Find player name for the DTO
        final player = provider.participants.firstWhere((p) => p.participantId == pId, orElse: () => provider.participants.first);
        starters.add({
          'playerId': pId,
          'playerName': player.participantName ?? 'Joueur',
          'position': idx.toString(), // The backend expects a string position
          'jerseyNumber': 0,
        });
      }
    });

    if (starters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un titulaire'), backgroundColor: OdinTheme.accentRed),
      );
      return;
    }

    setState(() => _saving = true);
    
    final success = await provider.saveMatchSheet(widget.eventId, {
      'formation': _formation,
      'starters': starters,
      'subs': [], // Logic for subs can be added later
      'validate': false,
    });

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feuille de match enregistrée !'), backgroundColor: OdinTheme.accentGreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Erreur lors de la sauvegarde'), backgroundColor: OdinTheme.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = Provider.of<EventsProvider>(context).participants;
    final players = participants.where((p) => p.status == 'confirmed').toList();

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Feuille de Match'),
        backgroundColor: OdinTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
            onPressed: _saving ? null : _saveLineup,
          ),
        ],
      ),
      body: Column(
        children: [
          // Formation Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: OdinTheme.surface,
            child: Row(
              children: [
                const Text('Formation:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ...['4-4-2', '4-3-3', '3-5-2'].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _formation == f,
                    onSelected: (val) => setState(() => _formation = f),
                    selectedColor: OdinTheme.primaryBlue,
                    backgroundColor: OdinTheme.surfaceLight,
                    labelStyle: TextStyle(color: _formation == f ? Colors.white : OdinTheme.textTertiary),
                  ),
                )),
              ],
            ),
          ),

          // Pitch Visualization
          Expanded(
            child: Stack(
              children: [
                // Field Background
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332), // Dark pitch green
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: CustomPaint(
                    painter: PitchPainter(),
                    size: Size.infinite,
                  ),
                ),

                // Player Positions
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spots = _formationsConfig[_formation]!;
                    return Stack(
                      children: List.generate(spots.length, (index) {
                        final pos = spots[index];
                        final playerId = _lineup[index];
                        final player = playerId != null ? players.firstWhere((p) => p.participantId == playerId) : null;

                        return Positioned(
                          left: pos.dx * (constraints.maxWidth - 32) + 8,
                          top: pos.dy * (constraints.maxHeight - 32) + 16,
                          child: _playerSpot(index, player),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),

          // Player Bench / Selection
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: OdinTheme.surface,
              border: const Border(top: BorderSide(color: OdinTheme.cardBorder)),
            ),
            child: players.isEmpty 
              ? const Center(child: Text('Aucun joueur confirmé', style: TextStyle(color: OdinTheme.textTertiary)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    final isUsed = _lineup.values.contains(p.participantId);
                    
                    return Draggable<String>(
                      data: p.participantId,
                      feedback: _playerAvatar(p, dragging: true),
                      childWhenDragging: Opacity(opacity: 0.3, child: _playerAvatar(p)),
                      child: Opacity(opacity: isUsed ? 0.3 : 1.0, child: _playerAvatar(p)),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _playerSpot(int index, dynamic player) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        setState(() {
          // Remove from other spot if exists
          _lineup.removeWhere((k, v) => v == details.data);
          _lineup[index] = details.data;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: candidateData.isNotEmpty ? OdinTheme.primaryBlue.withOpacity(0.5) : Colors.black26,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: player != null 
                ? const Icon(Icons.person, color: Colors.white, size: 24)
                : const Icon(Icons.add, color: Colors.white24, size: 20),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player != null ? (player.participantName ?? 'Joueur') : '...',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _playerAvatar(dynamic p, {bool dragging = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 60,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: OdinTheme.surfaceLight,
            child: const Icon(Icons.person, color: OdinTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            p.participantName ?? 'Joueur',
            style: const TextStyle(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer boundary exists from Container

    // Center line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    
    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);

    // Goal area (Bottom)
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, size.height - 60, size.width * 0.5, 60), paint);
    
    // Goal area (Top)
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, 0, size.width * 0.5, 60), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
