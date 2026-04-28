import 'package:flutter/material.dart';
import '../models/travel_model.dart';
import '../services/travel_api_service.dart';

class AirportSearchWidget extends StatefulWidget {
  final String label;
  final AirportInfo? selectedAirport;
  final ValueChanged<AirportInfo> onSelected;

  const AirportSearchWidget({
    super.key,
    required this.label,
    this.selectedAirport,
    required this.onSelected,
  });

  @override
  State<AirportSearchWidget> createState() => _AirportSearchWidgetState();
}

class _AirportSearchWidgetState extends State<AirportSearchWidget> {
  final TravelApiService _api = TravelApiService();
  final TextEditingController _controller = TextEditingController();
  List<AirportInfo> _results = [];
  bool _searching = false;

  Future<void> _search(String city) async {
    if (city.length < 2) return;
    setState(() { _searching = true; });
    try {
      final airports = await _api.searchAirportsDirect(city);
      setState(() { _results = airports; _searching = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _searching = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(
          color: Colors.white38, fontSize: 9, letterSpacing: 0.4)),
        const SizedBox(height: 4),

        // Champ de recherche
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: widget.selectedAirport?.name ?? 'Rechercher une ville...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1D9E75))),
                    )
                  : const Icon(Icons.search, color: Colors.white38, size: 16),
            ),
            onChanged: (val) {
              if (val.length >= 2) _search(val);
              else setState(() { _results = []; });
            },
          ),
        ),

        // Résultats de la recherche IA
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
            child: Column(
              children: _results.map((airport) => InkWell(
                onTap: () {
                  widget.onSelected(airport);
                  _controller.text = airport.name;
                  setState(() { _results = []; });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF185FA5).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(airport.code,
                          style: const TextStyle(color: Color(0xFF85B7EB), fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(airport.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                      const Icon(Icons.flight_takeoff, color: Colors.white38, size: 14),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ] else if (_controller.text.length >= 2 && !_searching && _results.isEmpty) ...[
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Aucun aéroport trouvé pour cette ville', 
              style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
          ),
        ],

        // Aéroport sélectionné
        if (widget.selectedAirport != null && _results.isEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF185FA5).withOpacity(0.25), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF5DCAA5), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${widget.selectedAirport!.code} · ${widget.selectedAirport!.name}',
                  style: const TextStyle(color: Color(0xFF85B7EB), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
