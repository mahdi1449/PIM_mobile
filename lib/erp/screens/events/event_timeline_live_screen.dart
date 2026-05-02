import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../models/match_live_event.dart';

class EventTimelineLiveScreen extends StatefulWidget {
  final String eventId;
  const EventTimelineLiveScreen({super.key, required this.eventId});

  @override
  State<EventTimelineLiveScreen> createState() => _EventTimelineLiveScreenState();
}

class _EventTimelineLiveScreenState extends State<EventTimelineLiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventsProvider>(context, listen: false).fetchLiveEvents(widget.eventId);
    });
  }

  void _showAddEventBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OdinTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddLiveEventSheet(eventId: widget.eventId),
    );
  }

  Widget _buildTimelineItem(MatchLiveEvent event, bool isLast) {
    Color iconColor = OdinTheme.textTertiary;
    IconData iconData = Icons.sports_soccer_rounded;

    if (event.type == 'goal') {
      iconColor = OdinTheme.accentGreen;
      iconData = Icons.sports_soccer_rounded;
    } else if (event.type == 'yellow_card') {
      iconColor = Colors.amber;
      iconData = Icons.style_rounded;
    } else if (event.type == 'red_card') {
      iconColor = OdinTheme.accentRed;
      iconData = Icons.style_rounded;
    } else if (event.type == 'substitution') {
      iconColor = OdinTheme.primaryBlue;
      iconData = Icons.sync_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${event.minute}\'', style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold))),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: OdinTheme.cardBorder,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: OdinTheme.glassCard,
                child: Row(
                  children: [
                    Icon(iconData, color: iconColor, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.displayTitle.toUpperCase(), style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(event.playerName ?? 'Action', style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          if (event.playerInName != null) ...[
                            const SizedBox(height: 2),
                            Text('Entrée: ${event.playerInName}', style: const TextStyle(color: OdinTheme.primaryBlue, fontSize: 12)),
                          ],
                          if (event.description != null && event.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(event.description!, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final events = provider.liveEvents;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Timeline Live', style: TextStyle(fontSize: 16)),
        backgroundColor: OdinTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: provider.isLoading && events.isEmpty
          ? const Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue))
          : events.isEmpty
              ? const Center(child: Text('Aucun événement', style: TextStyle(color: OdinTheme.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(events[index], index == events.length - 1);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: OdinTheme.accentRed,
        onPressed: _showAddEventBottomSheet,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _AddLiveEventSheet extends StatefulWidget {
  final String eventId;
  const _AddLiveEventSheet({required this.eventId});

  @override
  State<_AddLiveEventSheet> createState() => _AddLiveEventSheetState();
}

class _AddLiveEventSheetState extends State<_AddLiveEventSheet> {
  String _eventType = 'goal';
  final _minuteCtrl = TextEditingController();
  final _playerCtrl = TextEditingController(); // Basic manual text input for simplicity
  final _descCtrl = TextEditingController();
  bool _saving = false;

  void _submit() async {
    final m = int.tryParse(_minuteCtrl.text) ?? 0;
    if (m < 0) return;

    setState(() => _saving = true);
    final dto = {
      'type': _eventType,
      'minute': m,
      'playerName': _playerCtrl.text.isNotEmpty ? _playerCtrl.text : null,
      'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
    };

    final provider = Provider.of<EventsProvider>(context, listen: false);
    final ok = await provider.addLiveEvent(widget.eventId, dto);
    
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'ajout'), backgroundColor: OdinTheme.accentRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajouter un événement', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _eventType,
            dropdownColor: OdinTheme.surfaceLight,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Type d\'action',
              filled: true,
              fillColor: OdinTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: const [
              DropdownMenuItem(value: 'goal', child: Text('But')),
              DropdownMenuItem(value: 'yellow_card', child: Text('Carton Jaune')),
              DropdownMenuItem(value: 'red_card', child: Text('Carton Rouge')),
              DropdownMenuItem(value: 'substitution', child: Text('Remplacement')),
            ],
            onChanged: (v) => setState(() => _eventType = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _minuteCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Minute',
                    filled: true,
                    fillColor: OdinTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _playerCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom du Joueur',
                    filled: true,
                    fillColor: OdinTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Description (facultatif)',
              filled: true,
              fillColor: OdinTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OdinTheme.accentRed),
              onPressed: _saving ? null : _submit,
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('AJOUTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
