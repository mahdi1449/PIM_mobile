import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import 'event_player_stats_screen.dart';

class EventMatchResultScreen extends StatefulWidget {
  final String eventId;
  const EventMatchResultScreen({super.key, required this.eventId});

  @override
  State<EventMatchResultScreen> createState() => _EventMatchResultScreenState();
}

class _EventMatchResultScreenState extends State<EventMatchResultScreen> {
  int _homeScore = 0;
  int _awayScore = 0;
  int _duration = 90;
  bool _isHome = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EventsProvider>(context, listen: false);
    final event = provider.selectedEvent;
    if (event != null) {
      if (event.homeScore != null) _homeScore = event.homeScore!;
      if (event.awayScore != null) _awayScore = event.awayScore!;
      if (event.matchDuration != null) _duration = event.matchDuration!;
      // Determine if home based on title or location if needed
    }
  }

  String get _status {
    if (_homeScore > _awayScore) return 'VICTOIRE';
    if (_homeScore < _awayScore) return 'DÉFAITE';
    return 'NUL';
  }

  Color get _statusColor {
    if (_homeScore > _awayScore) return OdinTheme.accentGreen;
    if (_homeScore < _awayScore) return OdinTheme.accentRed;
    return OdinTheme.accentOrange;
  }

  Future<void> _publishResult() async {
    setState(() => _saving = true);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    // We update the result AND other metadata
    final success = await provider.setMatchResult(
      widget.eventId, 
      _homeScore, 
      _awayScore,
      duration: _duration,
      isHome: _isHome,
    );
    
    if (!mounted) return;
    setState(() => _saving = false);
    
    if (success) {
      // Navigate to player stats entry
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EventPlayerStatsScreen(eventId: widget.eventId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Erreur de publication'), backgroundColor: OdinTheme.accentRed),
      );
    }
  }

  Widget _scoreCounter(String label, int value, VoidCallback onInc, VoidCallback onDec, bool isHomeTeam) {
    return Column(
      children: [
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: OdinTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHomeTeam ? OdinTheme.primaryBlue.withOpacity(0.5) : OdinTheme.cardBorder,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
                color: OdinTheme.textSecondary,
                onPressed: onInc,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                color: OdinTheme.textSecondary,
                onPressed: onDec,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isHomeTeam ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final event = provider.selectedEvent;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('RÉSULTAT DU MATCH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Competition Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: OdinTheme.surfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event?.eventType.toUpperCase() ?? 'MATCH',
                  style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 24),

              // Scores
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scoreCounter('MON CLUB', _homeScore, () => setState(() => _homeScore++), () => setState(() { if (_homeScore > 0) _homeScore--; }), true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Text('VS', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _scoreCounter('ADVERSAIRE', _awayScore, () => setState(() => _awayScore++), () => setState(() { if (_awayScore > 0) _awayScore--; }), false),
                ],
              ),
              
              const SizedBox(height: 60),

              // Duration Selector
              _buildSectionTitle('DURÉE DU MATCH'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [90, 105, 120].map((d) {
                  final isSelected = _duration == d;
                  return GestureDetector(
                    onTap: () => setState(() => _duration = d),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 80) / 3,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? OdinTheme.primaryBlue : OdinTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? OdinTheme.primaryBlue : OdinTheme.cardBorder),
                      ),
                      child: Text(
                        '${d}\'',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : OdinTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Venue Toggle
              _buildSectionTitle('LIEU DU MATCH'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _venueButton('DOMICILE', true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _venueButton('EXTÉRIEUR', false),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OdinTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: OdinTheme.primaryBlue.withOpacity(0.5),
                  ),
                  onPressed: _saving ? null : _publishResult,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SUIVANT : STATS JOUEURS',
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: OdinTheme.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _venueButton(String label, bool value) {
    final isSelected = _isHome == value;
    return GestureDetector(
      onTap: () => setState(() => _isHome = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? OdinTheme.primaryBlue.withOpacity(0.1) : OdinTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? OdinTheme.primaryBlue : OdinTheme.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.stadium_rounded : Icons.directions_bus_rounded,
              size: 16,
              color: isSelected ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : OdinTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
