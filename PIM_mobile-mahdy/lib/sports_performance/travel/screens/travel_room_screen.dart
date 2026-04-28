import 'package:flutter/material.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';
import '../widgets/travel_ui_components.dart';

class TravelRoomScreen extends StatefulWidget {
  final TravelModel travel;
  final String clubId;
  const TravelRoomScreen({super.key, required this.travel, required this.clubId});

  @override
  State<TravelRoomScreen> createState() => _TravelRoomScreenState();
}

class _TravelRoomScreenState extends State<TravelRoomScreen> {
  final TravelApiService _api = TravelApiService();
  late List<HotelRoom> _rooms;
  HotelRoom? _selectedRoom;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rooms = List.from(widget.travel.hotel.rooms);
    if (_rooms.isNotEmpty) _selectedRoom = _rooms.first;
  }

  Future<void> _updateOccupant(String roomNumber, int pos, String playerId) async {
    setState(() => _isLoading = true);
    try {
      final roomIdx = _rooms.indexWhere((r) => r.roomNumber == roomNumber);
      final room = _rooms[roomIdx];
      String? occ1 = pos == 1 ? playerId : room.occupant1Id;
      String? occ2 = pos == 2 ? playerId : room.occupant2Id;

      await _api.updateRoomAssignment(
        travelId: widget.travel.id,
        clubId: widget.clubId,
        roomNumber: roomNumber,
        occupant1: occ1,
        occupant2: occ2,
      );

      // Rafraichissement local simple pour la démo
      setState(() {
        _rooms[roomIdx] = HotelRoom(
          roomNumber: roomNumber,
          type: room.type,
          occupant1Id: occ1,
          occupant1Name: pos == 1 ? 'Nouveau Joueur' : room.occupant1Name,
          occupant2Id: occ2,
          occupant2Name: pos == 2 ? 'Nouveau Joueur' : room.occupant2Name,
        );
        _isLoading = false;
        _selectedRoom = _rooms[roomIdx];
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelTheme.background,
      appBar: AppBar(
        title: const Text('RÉPARTITION DES CHAMBRES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Row(
        children: [
          // List Side
          Expanded(
            flex: 3,
            child: _buildRoomList(),
          ),
          // Edit Side (Panel)
          if (MediaQuery.of(context).size.width > 600)
            Expanded(
              flex: 2,
              child: _buildEditPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.travel.hotel.name, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13)),
        Text('${_rooms.length} chambres au total', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: TravelStatBox(label: 'Doubles', value: '${widget.travel.hotel.doubleRooms}')),
            const SizedBox(width: 8),
            Expanded(child: TravelStatBox(label: 'Singles', value: '${widget.travel.hotel.singleRooms}', color: TravelTheme.accentOrange)),
            const SizedBox(width: 8),
            Expanded(child: TravelStatBox(label: 'Personnes', value: '${widget.travel.participants.players.length + widget.travel.participants.staff.length}')),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Plan des chambres', style: TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._rooms.map((room) => _roomTile(room)),
      ],
    );
  }

  Widget _roomTile(HotelRoom room) {
    bool isSelected = _selectedRoom?.roomNumber == room.roomNumber;
    bool isOccupied = room.occupant1Id != null || room.occupant2Id != null;
    
    Color typeColor = TravelTheme.accentBlue;
    if (room.type == 'single') typeColor = TravelTheme.accentOrange;
    if (room.type == 'suite') typeColor = Colors.purpleAccent;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRoom = room);
        if (MediaQuery.of(context).size.width <= 600) {
           _showEditBottomSheet(room);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? typeColor.withOpacity(0.05) : TravelTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? typeColor : Colors.white.withOpacity(0.05), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.hotel_outlined, color: typeColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Chambre ${room.roomNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(room.type.toUpperCase(), style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${room.occupant1Name ?? "Libre"} · ${room.occupant2Name ?? "Libre"}', 
                    style: TextStyle(color: isOccupied ? TravelTheme.textMuted : Colors.white24, fontSize: 11)),
                ],
              ),
            ),
            if (MediaQuery.of(context).size.width <= 600)
               const Icon(Icons.edit_outlined, color: Colors.white24, size: 16),
            const SizedBox(width: 12),
            Container(
              width: 8, height: 8, 
              decoration: BoxDecoration(
                color: isOccupied ? TravelTheme.accentGreen : Colors.white10, 
                shape: BoxShape.circle,
                boxShadow: isOccupied ? [BoxShadow(color: TravelTheme.accentGreen.withOpacity(0.5), blurRadius: 4)] : null,
              )
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBottomSheet(HotelRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TravelTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
             const SizedBox(height: 24),
             _buildEditPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPanel() {
    if (_selectedRoom == null) return const Center(child: Text('Sélectionnez une chambre', style: TextStyle(color: Colors.white24)));
    final room = _selectedRoom!;

    return Container(
      decoration: BoxDecoration(color: TravelTheme.cardBg, border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05)))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modifier la chambre', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Drag & drop pour échanger', style: TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 32),
          Text('Chambre ${room.roomNumber} — ${room.type}', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _occupantItem(room.occupant1Name, 'Occupant 1'),
          const SizedBox(height: 12),
          if (room.type == 'double') _occupantItem(room.occupant2Name, 'Occupant 2'),
          
          const Spacer(),
          const Text('Changer un occupant', style: TextStyle(color: TravelTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sélectionner un joueur...', style: TextStyle(color: Colors.white24, fontSize: 13)),
                Icon(Icons.keyboard_arrow_down, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: TravelTheme.accentGreen,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _occupantItem(String? name, String role) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: TravelTheme.accentBlue.withOpacity(0.2), radius: 18, child: const Icon(Icons.person, color: TravelTheme.accentBlue, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Libre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(role, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.drag_handle, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}
