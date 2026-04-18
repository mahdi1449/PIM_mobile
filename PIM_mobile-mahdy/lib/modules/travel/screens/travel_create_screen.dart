import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../sports_performance/theme/sp_colors.dart';
import '../models/travel_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';
import '../widgets/airport_search_widget.dart';
import '../widgets/place_search_widget.dart';
import '../../../sports_performance/models/player.dart';
import '../../../sports_performance/providers/players_provider.dart';
import '../../../services/api_service.dart';

class TravelCreateScreen extends ConsumerStatefulWidget {
  final String clubId;
  final TravelModel? travelToEdit;
  const TravelCreateScreen({super.key, required this.clubId, this.travelToEdit});

  @override
  ConsumerState<TravelCreateScreen> createState() => _TravelCreateScreenState();
}

class _TravelCreateScreenState extends ConsumerState<TravelCreateScreen> {
  final TravelApiService _api = TravelApiService();
  final ApiService _generalApi = ApiService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isDataLoading = true;

  // Club Data
  List<Player> _allPlayers = [];
  List<Map<String, dynamic>> _allStaff = [];

  // Form Data
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _hotelAddressController = TextEditingController();
  
  double? _destLat, _destLng;
  double? _hotelLat, _hotelLng;
  String? _hotelPhone, _hotelWebsite;
  
  String _travelType = 'away';
  String _travelMode = 'bus';
  DateTime _departureAt = DateTime.now().add(const Duration(days: 1));
  DateTime _returnAt = DateTime.now().add(const Duration(days: 2));
  
  AirportInfo? _depAirport;
  AirportInfo? _arrAirport;

  // Participants & Rooms
  final List<String> _selectedPlayerIds = [];
  final List<String> _selectedStaffIds = [];
  final List<HotelRoom> _rooms = [];

  @override
  void initState() {
    super.initState();
    if (widget.travelToEdit != null) {
      _initEditMode();
    }
    _loadClubData();
  }

  void _initEditMode() {
    final t = widget.travelToEdit!;
    _destController.text = t.destination;
    _destLat = t.destinationLat;
    _destLng = t.destinationLng;
    _travelType = t.type;
    _travelMode = t.departure.mode;
    _departureAt = t.departure.at;
    _returnAt = t.travelReturn.at;
    _depAirport = t.departureAirport;
    _arrAirport = t.arrivalAirport;
    
    _hotelNameController.text = t.hotel.name;
    _hotelAddressController.text = t.hotel.address;
    _hotelLat = t.hotel.lat;
    _hotelLng = t.hotel.lng;
    _hotelPhone = t.hotel.phone;
    _hotelWebsite = t.hotel.website;

    _selectedPlayerIds.addAll(t.participants.players.map((p) => p.id));
    _selectedStaffIds.addAll(t.participants.staff.map((s) => s.id));
    _rooms.addAll(t.hotel.rooms);
  }

  Future<void> _loadClubData() async {
    try {
      final players = await ref.read(playersProvider.future);
      final coachesData = await _generalApi.getCoaches();
      
      setState(() {
        _allPlayers = players;
        if (coachesData['success'] == true) {
          _allStaff = List<Map<String, dynamic>>.from(coachesData['data'] ?? []);
        }
        _isDataLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? _departureAt : _returnAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: SPColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) _departureAt = picked;
        else _returnAt = picked;
      });
    }
  }

  void _submit() async {
    if (_destController.text.isEmpty || _hotelNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les informations obligatoires')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'clubId': widget.clubId,
        'matchId': '65f1a2b3c4d5e6f7a8b9c0d1',
        'destination': _destController.text,
        'destinationLat': _destLat,
        'destinationLng': _destLng,
        'type': _travelType,
        'departure': {
          'at': _departureAt.toIso8601String(),
          'from': 'Tunis',
          'mode': _travelMode,
          'flightNumber': _travelMode == 'flight' ? 'TU711' : null,
        },
        'return': {
          'at': _returnAt.toIso8601String(),
        },
        'hotel': {
          'name': _hotelNameController.text,
          'address': _hotelAddressController.text,
          'phone': _hotelPhone,
          'website': _hotelWebsite,
          'lat': _hotelLat,
          'lng': _hotelLng,
          'checkIn': _departureAt.toIso8601String(),
          'checkOut': _returnAt.toIso8601String(),
          'rooms': _rooms.map((r) => {
            'roomNumber': r.roomNumber,
            'type': r.type,
            'occupant1': r.occupant1Id,
            'occupant2': r.occupant2Id,
            'isStaffRoom': r.isStaffRoom,
          }).toList(),
        },
        'participants': { 
          'players': _selectedPlayerIds, 
          'staff': _selectedStaffIds 
        },
      };

      if (widget.travelToEdit != null) {
        await _api.updateTravel(widget.travelToEdit!.id, payload);
      } else {
        await _api.createTravel(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('NOUVEAU DÉPLACEMENT'),
        backgroundColor: Colors.transparent,
      ),
      body: (_isLoading || _isDataLoading)
        ? const Center(child: CircularProgressIndicator(color: SPColors.primaryBlue))
        : Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) setState(() => _currentStep++);
              else _submit();
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 4 ? 'CONFIRMER' : 'CONTINUER'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(onPressed: details.onStepCancel, child: const Text('RETOUR')),
                ],
              ),
            ),
            steps: [
              Step(
                title: const Text('Destination & Match', style: TextStyle(color: Colors.white, fontSize: 14)),
                content: _buildGeneralStep(),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Logistique Transport', style: TextStyle(color: Colors.white, fontSize: 14)),
                content: _buildTransportStep(),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text('Hôtel & Hébergement', style: TextStyle(color: Colors.white, fontSize: 14)),
                content: _buildHotelStep(),
                isActive: _currentStep >= 2,
              ),
              Step(
                title: const Text('Sélection des Participants', style: TextStyle(color: Colors.white, fontSize: 14)),
                content: _buildParticipantsStep(),
                isActive: _currentStep >= 3,
              ),
              Step(
                title: const Text('Rooming List', style: TextStyle(color: Colors.white, fontSize: 14)),
                content: _buildRoomingStep(),
                isActive: _currentStep >= 4,
              ),
            ],
          ),
    );
  }

  Widget _buildGeneralStep() {
    return Column(
      children: [
        PlaceSearchWidget(
          label: 'VILLE DE DESTINATION (IA)',
          hint: 'Rechercher une ville...',
          icon: Icons.location_city,
          onChanged: (val) => setState(() => _destController.text = val),
          onSelected: (name, addr, lat, lng, extra) {
            setState(() {
              _destController.text = name;
              _destLat = lat;
              _destLng = lng;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _dateTile('Départ', _departureAt, () => _selectDate(context, true))),
            const SizedBox(width: 12),
            Expanded(child: _dateTile('Retour', _returnAt, () => _selectDate(context, false))),
          ],
        ),
      ],
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SPColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SPColors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: SPColors.textTertiary, fontSize: 10)),
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportStep() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _travelMode,
          dropdownColor: SPColors.backgroundSecondary,
          decoration: const InputDecoration(labelText: 'Mode de transport'),
          items: ['bus', 'flight', 'train', 'car'].map((m) => DropdownMenuItem(
            value: m, child: Text(m.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
          onChanged: (val) => setState(() => _travelMode = val!),
        ),
        if (_travelMode == 'flight') ...[
          const SizedBox(height: 16),
          AirportSearchWidget(
            label: 'Aéroport de départ (IA)',
            onSelected: (a) => setState(() => _depAirport = a),
          ),
          const SizedBox(height: 12),
          AirportSearchWidget(
            label: 'Aéroport d\'arrivée (IA)',
            onSelected: (a) => setState(() {
              _arrAirport = a;
              if (_destController.text.isEmpty) {
                _destController.text = a.name.split(' ').first;
              }
            }),
          ),
        ]
      ],
    );
  }

  Widget _buildHotelStep() {
    return Column(
      children: [
        PlaceSearchWidget(
          label: 'NOM DE L\'ÉTABLISSEMENT (IA)',
          hint: 'Rechercher un hôtel...',
          icon: Icons.hotel,
          cityContext: _destController.text,
          onSelected: (name, addr, lat, lng, extra) {
            setState(() {
              _hotelNameController.text = name;
              _hotelAddressController.text = addr;
              _hotelLat = lat;
              _hotelLng = lng;
              _hotelPhone = extra?['phone'];
              _hotelWebsite = extra?['website'];
            });
          },
        ),
        const SizedBox(height: 16),
        PlaceSearchWidget(
          label: 'ADRESSE COMPLÈTE (IA)',
          hint: 'Saisir ou rechercher l\'adresse...',
          icon: Icons.map,
          cityContext: _destController.text,
          initialValue: _hotelAddressController.text,
          onChanged: (val) => setState(() => _hotelAddressController.text = val),
          onSelected: (name, addr, lat, lng, extra) {
            setState(() {
              _hotelAddressController.text = addr;
              _hotelLat = lat;
              _hotelLng = lng;
              if (extra?['phone'] != null) _hotelPhone = extra?['phone'];
              if (extra?['website'] != null) _hotelWebsite = extra?['website'];
            });
          },
        ),
      ],
    );
  }

  // ─── ÉTAPE 3 : PARTICIPANTS ──────────────────────────────────────────────
  Widget _buildParticipantsStep() {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TabBar(
            tabs: [ Tab(text: 'Joueurs'), Tab(text: 'Staff') ],
            labelColor: SPColors.primaryBlue,
            unselectedLabelColor: Colors.white38,
            indicatorColor: SPColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                _buildParticipantsList('players'),
                _buildParticipantsList('staff'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(String type) {
    final items = type == 'players' ? _allPlayers : _allStaff;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final id = type == 'players' ? (item as Player).id : (item as Map)['_id'];
        final name = type == 'players' ? (item as Player).fullName : (item as Map)['fullName'] ?? (item as Map)['name'];
        final isSelected = type == 'players' ? _selectedPlayerIds.contains(id) : _selectedStaffIds.contains(id);

        return CheckboxListTile(
          title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          secondary: type == 'players' && (item as Player).photo != null
            ? CircleAvatar(radius: 12, backgroundImage: NetworkImage((item as Player).photo!))
            : null,
          subtitle: type == 'players' 
            ? Text((item as Player).position, style: const TextStyle(color: Colors.white24, fontSize: 11))
            : Text((item as Map)['role'] ?? 'Staff', style: const TextStyle(color: Colors.white24, fontSize: 11)),
          value: isSelected,
          activeColor: SPColors.primaryBlue,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                if (type == 'players') _selectedPlayerIds.add(id); else _selectedStaffIds.add(id);
              } else {
                if (type == 'players') _selectedPlayerIds.remove(id); else _selectedStaffIds.remove(id);
              }
            });
          },
        );
      },
    );
  }

  // ─── ÉTAPE 4 : ROOMING LIST ───────────────────────────────────────────────
  Widget _buildRoomingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_rooms.length} Chambres configurées', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            TextButton.icon(
              onPressed: _addRoom,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('AJOUTER'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_rooms.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune chambre. Ajoutez-en une !', style: TextStyle(color: Colors.white24, fontSize: 12)))),
        
        ..._rooms.asMap().entries.map((entry) => _buildRoomCard(entry.key, entry.value)),
      ],
    );
  }

  void _addRoom() {
    setState(() {
      _rooms.add(HotelRoom(
        roomNumber: '${100 + _rooms.length + 1}',
        type: 'double',
      ));
    });
  }

  Widget _buildRoomCard(int index, HotelRoom room) {
    // Participants disponibles pour cette chambre
    final availablePlayers = _allPlayers.where((p) => _selectedPlayerIds.contains(p.id)).toList();
    final availableStaff = _allStaff.where((s) => _selectedStaffIds.contains(s['_id'])).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hotel, size: 16, color: SPColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(child: Text('Chambre ${room.roomNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              DropdownButton<String>(
                value: room.type,
                dropdownColor: SPColors.backgroundSecondary,
                underline: const SizedBox(),
                items: ['single', 'double', 'suite'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)))).toList(),
                onChanged: (val) => setState(() {
                   _rooms[index] = HotelRoom(roomNumber: room.roomNumber, type: val!, occupant1Id: room.occupant1Id, occupant2Id: room.occupant2Id, isStaffRoom: room.isStaffRoom);
                }),
              ),
              IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.white24), onPressed: () => setState(() => _rooms.removeAt(index))),
            ],
          ),
          const Divider(color: Colors.white10),
          _buildOccupantSelector(index, 1, room.occupant1Id, availablePlayers, availableStaff),
          if (room.type != 'single')
            _buildOccupantSelector(index, 2, room.occupant2Id, availablePlayers, availableStaff),
        ],
      ),
    );
  }

  Widget _buildOccupantSelector(int roomIdx, int occIdx, String? currentId, List<Player> players, List<Map<String, dynamic>> staff) {
    return Row(
      children: [
        Text('Occupant $occIdx :', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: currentId,
            hint: const Text('Choisir...', style: TextStyle(color: Colors.white12, fontSize: 12)),
            dropdownColor: SPColors.backgroundTertiary,
            items: [
              ...players.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName, style: const TextStyle(color: Colors.white, fontSize: 12)))),
              ...staff.map((s) => DropdownMenuItem(value: s['_id'], child: Text(s['fullName'] ?? s['name'], style: const TextStyle(color: Colors.white70, fontSize: 12)))),
            ],
            onChanged: (val) {
              setState(() {
                final r = _rooms[roomIdx];
                _rooms[roomIdx] = HotelRoom(
                  roomNumber: r.roomNumber,
                  type: r.type,
                  occupant1Id: occIdx == 1 ? val : r.occupant1Id,
                  occupant2Id: occIdx == 2 ? val : r.occupant2Id,
                  isStaffRoom: r.isStaffRoom,
                );
              });
            },
          ),
        ),
        if (currentId != null)
          IconButton(icon: const Icon(Icons.clear, size: 14, color: Colors.white24), onPressed: () {
            setState(() {
              final r = _rooms[roomIdx];
               _rooms[roomIdx] = HotelRoom(roomNumber: r.roomNumber, type: r.type, occupant1Id: occIdx == 1 ? null : r.occupant1Id, occupant2Id: occIdx == 2 ? null : r.occupant2Id, isStaffRoom: r.isStaffRoom);
            });
          }),
      ],
    );
  }
}
