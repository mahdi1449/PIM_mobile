import 'dart:async';
import 'package:flutter/material.dart';
import '../services/travel_api_service.dart';

class PlaceSearchWidget extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? cityContext;
  final String? initialValue;
  final void Function(String name, String address, double? lat, double? lng, Map<String, dynamic>? extra) onSelected;
  final ValueChanged<String>? onChanged;

  const PlaceSearchWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.cityContext,
    this.initialValue,
    required this.onSelected,
    this.onChanged,
  });

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TravelApiService _api = TravelApiService();
  late TextEditingController _controller;
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _noResultsFound = false;
  Timer? _debounce; // Pour éviter de spammer le serveur

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(PlaceSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Déterminer si on cherche un hôtel ou un lieu général
    bool isHotelSearch = widget.icon == Icons.hotel || widget.label.contains('HÔTEL') || widget.label.contains('ÉTABLISSEMENT');
    String city = widget.cityContext ?? '';
    
    String finalQuery = query;
    if (query.isEmpty && city.isNotEmpty) {
      // Recherche proactive via bouton IA
      finalQuery = isHotelSearch ? 'hotel, $city' : city;
    } else if (city.isNotEmpty && !query.contains(city)) {
      finalQuery = '$query, $city';
    }

    if (finalQuery.length < 3) return;

    // Délai de 500ms avant de lancer la recherche réelle
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _searching = true;
        _noResultsFound = false;
      });
      
      try {
        // Tentative 1 : Recherche optimisée
        var results = await _api.searchPlaces(finalQuery);
        
        // Tentative 2 (Fallback) : Si hôtel et aucun résultat, essayer une syntaxe plus large
        if (results.isEmpty && isHotelSearch && query.isEmpty) {
          results = await _api.searchPlaces('$city hotel');
        }
        
        // Tentative 3 (Dernier recours) : Recherche brute sur la ville
        if (results.isEmpty && query.isEmpty) {
          results = await _api.searchPlaces(city);
        }

        if (mounted) {
          setState(() {
            _results = results;
            _searching = false;
            _noResultsFound = results.isEmpty;
          });
        }
      } catch (e) {
        if (mounted) setState(() {
          _searching = false;
          _noResultsFound = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5)),
            if (widget.cityContext != null && widget.cityContext!.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _search(''),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF1D9E75)),
                        const SizedBox(width: 4),
                        Text('RECHERCHE IA : ${widget.cityContext!.toUpperCase()}', 
                          style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: Icon(widget.icon, size: 18, color: const Color(0xFF1D9E75)),
              suffixIcon: _searching 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 14, height: 14, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75))),
                  )
                : (_controller.text.isNotEmpty ? IconButton(
                    icon: const Icon(Icons.clear, size: 14, color: Colors.white38),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _results = []);
                      if (widget.onChanged != null) widget.onChanged!('');
                    },
                  ) : const Icon(Icons.search, size: 18, color: Colors.white38)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (val) {
              if (widget.onChanged != null) widget.onChanged!(val);
              if (val.length >= 3) _search(val);
              else if (val.isEmpty && widget.cityContext != null) _search('');
              else setState(() => _results = []);
            },
          ),
        ),
        if (_searching && _results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Recherche IA en cours...', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
          ),
        if (_noResultsFound)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aucun résultat trouvé via l\'IA.', 
                  style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('Vous pouvez simplement saisir votre texte et continuer.',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                ),
                if (_api.lastError != null && _api.lastError!.contains('Timeout'))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Détail: Service momentanément indisponible.', 
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final place = _results[index];
                final displayName = place['display_name'] ?? '';
                final name = place['name'] ?? place['display_name']?.split(',')[0] ?? '';
                
                final extra = place['extratags'] as Map<String, dynamic>?;
                final phone = extra?['phone'] ?? extra?['contact:phone'];
                final website = extra?['website'] ?? extra?['contact:website'];
                final stars = extra?['stars'];

                return ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      if (stars != null) ...[
                        const Icon(Icons.star, size: 10, color: Colors.amber),
                        Text(stars.toString(), style: const TextStyle(color: Colors.amber, fontSize: 10)),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      if (phone != null || website != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (phone != null) ...[
                              const Icon(Icons.phone, size: 10, color: Color(0xFF1D9E75)),
                              const SizedBox(width: 4),
                              Text(phone, style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 9)),
                              const SizedBox(width: 10),
                            ],
                            if (website != null) ...[
                              const Icon(Icons.language, size: 10, color: Colors.white38),
                              const SizedBox(width: 4),
                              Expanded(child: Text(website, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 9))),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    _controller.text = name;
                    widget.onSelected(
                      name,
                      displayName,
                      double.tryParse(place['lat']?.toString() ?? ''),
                      double.tryParse(place['lon']?.toString() ?? ''),
                      {
                        'phone': phone,
                        'website': website,
                        'stars': stars,
                      },
                    );
                    setState(() => _results = []);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
