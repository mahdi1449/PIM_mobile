import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../providers/players_provider.dart';

class EventPlayerPickerScreen extends StatefulWidget {
  final String eventId;
  const EventPlayerPickerScreen({super.key, required this.eventId});

  @override
  State<EventPlayerPickerScreen> createState() => _EventPlayerPickerScreenState();
}

class _EventPlayerPickerScreenState extends State<EventPlayerPickerScreen> {
  final Set<String> _selectedPlayerIds = {};
  final _meetingTime = TextEditingController();
  final _requiredKit = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayersProvider>(context, listen: false).fetchPlayers();
      // Pre-select existing participants
      final existing = Provider.of<EventsProvider>(context, listen: false).participants;
      setState(() {
        _selectedPlayerIds.addAll(existing.map((p) => p.participantId));
      });
    });
  }

  @override
  void dispose() {
    _meetingTime.dispose();
    _requiredKit.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un joueur'), backgroundColor: OdinTheme.accentRed),
      );
      return;
    }

    // Show confirmation/details dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OdinTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails de la convocation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _textField(_meetingTime, 'Heure de rendez-vous (ex: 14:30)', Icons.access_time_rounded),
            const SizedBox(height: 12),
            _textField(_requiredKit, 'Tenue requise (ex: Pack Match Bleu)', Icons.checkroom_rounded),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OdinTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _confirmSend(ctx),
                child: const Text('ENVOYER LES CONVOCATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSend(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    final success = await provider.sendConvocations(
      widget.eventId,
      _selectedPlayerIds.toList(),
      meetingTime: _meetingTime.text.trim().isNotEmpty ? _meetingTime.text.trim() : null,
      requiredKit: _requiredKit.text.trim().isNotEmpty ? _requiredKit.text.trim() : null,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convocations envoyées avec succès !'), backgroundColor: OdinTheme.accentGreen),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Erreur lors de l\'envoi'), backgroundColor: OdinTheme.accentRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = Provider.of<PlayersProvider>(context).players;
    final filteredPlayers = players.where((p) {
      final name = '${p.firstName} ${p.lastName}'.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Sélection des joueurs'),
        backgroundColor: OdinTheme.surface,
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Valider', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                hintStyle: const TextStyle(color: OdinTheme.textTertiary),
                prefixIcon: const Icon(Icons.search, color: OdinTheme.textTertiary),
                filled: true,
                fillColor: OdinTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final isSelected = _selectedPlayerIds.contains(player.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  activeColor: OdinTheme.primaryBlue,
                  checkColor: Colors.white,
                  title: Text('${player.firstName} ${player.lastName}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(player.position, style: const TextStyle(color: OdinTheme.textTertiary)),
                  secondary: CircleAvatar(
                    backgroundColor: OdinTheme.surfaceLight,
                    child: const Icon(Icons.person, color: OdinTheme.textTertiary),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPlayerIds.add(player.id);
                      } else {
                        _selectedPlayerIds.remove(player.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: OdinTheme.surface,
          border: const Border(top: BorderSide(color: OdinTheme.cardBorder)),
        ),
        child: Text(
          '${_selectedPlayerIds.length} joueur(s) sélectionné(s)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: OdinTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: OdinTheme.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: OdinTheme.textTertiary, size: 20),
        filled: true,
        fillColor: OdinTheme.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
