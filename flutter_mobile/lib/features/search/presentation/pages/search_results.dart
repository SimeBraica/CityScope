import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobile/features/search/model/search_result.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobile/features/search/presentation/pages/place_details.dart';

class SearchResultsPage extends StatefulWidget {
  final List<SearchResult> results;
  final LatLng userLocation;
  
  const SearchResultsPage({
    Key? key, 
    required this.results,
    required this.userLocation,
  }) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  int _currentView = 0; // 0 = lista, 1 = mapa
  GoogleMapController? _mapController;
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.searchResults ?? 'Rezultati pretrage',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_currentView == 0 ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _currentView = _currentView == 0 ? 1 : 0;
              });
            },
          ),
        ],
      ),
      body: widget.results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    loc.noResultsFound ?? 'Nema rezultata za vašu pretragu',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _currentView == 0
              ? _buildListView()
              : _buildMapView(),
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.results.length,
      itemBuilder: (context, index) {
        final result = widget.results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailsPage(place: result),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      result.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(result.category),
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (result.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    result.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (result.description != null)
                        Text(
                          result.description!,
                          style: TextStyle(color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF368564)),
                          const SizedBox(width: 4),
                          Text(
                            result.distance != null
                                ? '${result.distance!.toStringAsFixed(1)} km'
                                : 'Nepoznata udaljenost',
                            style: const TextStyle(color: Color(0xFF368564)),
                          ),
                          const SizedBox(width: 16),
                          if (result.price != null) ...[
                            const Icon(Icons.euro, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _getPriceLabel(result.price!),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMapView() {
    final Set<Marker> markers = widget.results.map((result) {
      return Marker(
        markerId: MarkerId(result.id),
        position: result.location,
        infoWindow: InfoWindow(
          title: result.name,
          snippet: result.description,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceDetailsPage(place: result),
              ),
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getCategoryHue(result.category)),
      );
    }).toSet();
    
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: widget.userLocation,
        infoWindow: InfoWindow(
          title: AppLocalizations.of(context)?.yourLocation ?? 'Vaša lokacija',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLocation,
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: markers,
      onMapCreated: (controller) => _mapController = controller,
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'attractions':
        return Icons.park;
      case 'culture':
        return Icons.museum;
      case 'music':
        return Icons.music_note;
      case 'hobbies':
        return Icons.sports;
      default:
        return Icons.place;
    }
  }
  
  double _getCategoryHue(String category) {
    switch (category) {
      case 'food':
        return BitmapDescriptor.hueRed;
      case 'attractions':
        return BitmapDescriptor.hueGreen;
      case 'culture':
        return BitmapDescriptor.hueViolet;
      case 'music':
        return BitmapDescriptor.hueYellow;
      case 'hobbies':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRose;
    }
  }
  
  String _getPriceLabel(double price) {
    if (price <= 0) return 'Besplatno';
    if (price <= 10) return '€';
    if (price <= 30) return '€€';
    if (price <= 60) return '€€€';
    return '€€€€';
  }
} 