import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobile/features/search/model/search_result.dart';
import 'package:flutter_mobile/features/search/services/search_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsPage extends StatefulWidget {
  final SearchResult place;
  
  const PlaceDetailsPage({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  final SearchService _searchService = SearchService();
  bool _isLoading = true;
  Map<String, dynamic>? _placeDetails;
  String? _fact;
  bool _hasDetailedInfo = false;
  Map<String, String?>? _wikipediaInfo;
  bool _isLoadingWikipedia = false;
  bool _isLoadingAiFact = false;
  
  @override
  void initState() {
    super.initState();
    _loadPlaceDetails();
  }
  
  Future<void> _loadPlaceDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final details = await _searchService.getPlaceDetails(widget.place.id);
      
      if (details != null) {
        setState(() {
          _placeDetails = details;
          
          _hasDetailedInfo = details['editorial_summary'] != null || 
                            (details['reviews'] != null && (details['reviews'] as List).isNotEmpty);

          final bool isCulturalObject = 
              widget.place.category == 'culture' || 
              widget.place.category == 'attractions' ||
              widget.place.subcategory == 'church' ||
              widget.place.subcategory == 'place_of_worship' ||
              widget.place.subcategory == 'museum' ||
              widget.place.subcategory == 'art_gallery' ||
              widget.place.subcategory == 'library' ||
              widget.place.subcategory == 'tourist_attraction' ||
              (details['types'] != null && 
               ((details['types'] as List<dynamic>).contains('church') ||
                (details['types'] as List<dynamic>).contains('place_of_worship') ||
                (details['types'] as List<dynamic>).contains('museum') ||
                (details['types'] as List<dynamic>).contains('art_gallery') || 
                (details['types'] as List<dynamic>).contains('library') ||
                (details['types'] as List<dynamic>).contains('tourist_attraction')));

          if (isCulturalObject) {
            _loadWikipediaInfo();
          } else {
            _generateAiFact();
          }
        });
      }
    } catch (e) {
      print('Greška pri dohvaćanju detalja: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateAiFact() async {
    print('Započinjem generiranje AI činjenice za: ${widget.place.name}');
    
    setState(() {
      _isLoadingAiFact = true;
    });
    
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final fact = await _searchService.getAiFunFact(
        widget.place.name,
        widget.place.category,
        widget.place.subcategory,
        _wikipediaInfo,
        _placeDetails,
        locale
      );
      
      print('Dobivena AI činjenica: $fact');
      
      if (mounted) {
        setState(() {
          _fact = fact;
          _isLoadingAiFact = false;
        });
      }
    } catch (e) {
      print('Greška pri generiranju AI činjenice: $e');
      if (mounted) {
        setState(() {
          _fact = _getDefaultFactLocally();
          _isLoadingAiFact = false;
        });
      }
    }
  }
  
  Future<void> _loadWikipediaInfo() async {
    final bool isCulturalObject = 
        widget.place.category == 'culture' || 
        widget.place.category == 'attractions' ||
        widget.place.subcategory == 'church' ||
        widget.place.subcategory == 'place_of_worship' ||
        widget.place.subcategory == 'museum' ||
        widget.place.subcategory == 'art_gallery' ||
        widget.place.subcategory == 'library' ||
        widget.place.subcategory == 'tourist_attraction' ||
        (_placeDetails != null && _placeDetails!['types'] != null && 
          ((_placeDetails!['types'] as List<dynamic>).contains('church') ||
           (_placeDetails!['types'] as List<dynamic>).contains('place_of_worship') ||
           (_placeDetails!['types'] as List<dynamic>).contains('museum') ||
           (_placeDetails!['types'] as List<dynamic>).contains('art_gallery') ||
           (_placeDetails!['types'] as List<dynamic>).contains('library') ||
           (_placeDetails!['types'] as List<dynamic>).contains('tourist_attraction')));
    
    if (!isCulturalObject) {
      print('Nije kulturni objekt: ${widget.place.name} (kategorija: ${widget.place.category}, potkategorija: ${widget.place.subcategory})');
      return;
    }
    
    print('Pokretanje Wikipedia pretrage za: ${widget.place.name}');
    
    setState(() {
      _isLoadingWikipedia = true;
    });
    
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final info = await _searchService.getWikipediaInfo(widget.place.name, locale);
      
      if (info.containsKey('error')) {
        print('Nije moguće dohvatiti Wikipedia podatke za ${widget.place.name}: ${info['error']}');
      } else {
        print('Uspješno dohvaćeni Wikipedia podaci za ${widget.place.name}');
        setState(() {
          _wikipediaInfo = info;
        });
      }
      
      _generateAiFact();
      
    } catch (e) {
      print('Greška pri dohvaćanju Wikipedia podataka za ${widget.place.name}: $e');
      _generateAiFact();
    } finally {
      setState(() {
        _isLoadingWikipedia = false;
      });
    }
  }
  
  // Pomoćna metoda koja vraća lokalnu zadanu činjenicu ako AI ne uspije
  String _getDefaultFactLocally() {
    final locale = Localizations.localeOf(context).languageCode;
    
    if (locale == 'hr') {
      if (widget.place.category == 'culture' || widget.place.category == 'attractions') {
        if (widget.place.subcategory == 'church' || widget.place.subcategory == 'place_of_worship') {
          return "Značajan sakralni objekt u hrvatskoj kulturnoj baštini";
        } else if (widget.place.subcategory == 'museum') {
          return "Muzej s vrijednom zbirkom eksponata koji predstavljaju kulturnu baštinu";
        } else if (widget.place.subcategory == 'art_gallery') {
          return "Galerija koja predstavlja važna umjetnička djela hrvatskih i stranih autora";
        } else {
          return "Značajan objekt hrvatske kulturne baštine";
        }
      } else {
        return "Zanimljiva lokacija u Hrvatskoj vrijedna posjeta";
      }
    } else {
      // Engleske verzije
      if (widget.place.category == 'culture' || widget.place.category == 'attractions') {
        if (widget.place.subcategory == 'church' || widget.place.subcategory == 'place_of_worship') {
          return "Significant religious site in Croatian cultural heritage";
        } else if (widget.place.subcategory == 'museum') {
          return "Museum with a valuable collection of exhibits representing cultural heritage";
        } else if (widget.place.subcategory == 'art_gallery') {
          return "Gallery presenting important artworks by Croatian and international artists";
        } else {
          return "Significant site in Croatian cultural heritage";
        }
      } else {
        return "An interesting location in Croatia worth visiting";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlaceInfo(),
              if (_fact != null || _isLoadingAiFact) _buildFactSection(),
              if (_wikipediaInfo != null && _wikipediaInfo!['articleUrl'] != null)
                _buildWikipediaLink(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _hasDetailedInfo 
                    ? ElevatedButton(
                        onPressed: () {
                          _showFullDetails();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF368564),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.details ?? 'DETALJI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppBar() {
    String headerImageUrl = '';
    
    if ((widget.place.category == 'culture' || widget.place.category == 'attractions') && 
        _wikipediaInfo != null && 
        _wikipediaInfo!['imageUrl'] != null) {
      headerImageUrl = _wikipediaInfo!['imageUrl']!;
    } else if (_placeDetails != null && 
               _placeDetails!['photos'] != null && 
               (_placeDetails!['photos'] as List).isNotEmpty) {
      headerImageUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${_placeDetails!['photos'][0]['photo_reference']}&key=${_searchService.apiKey}';
    } else if (widget.place.imageUrl != null) {
      headerImageUrl = widget.place.imageUrl!;
    }
      
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: headerImageUrl.isNotEmpty
          ? Image.network(
              headerImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(widget.place.category),
                      size: 72,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey.shade300,
              child: Center(
                child: Icon(
                  _getCategoryIcon(widget.place.category),
                  size: 72,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  Widget _buildPlaceInfo() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.place.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _placeDetails?['vicinity'] ?? widget.place.description ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.place.rating != null) ...[
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  widget.place.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_placeDetails != null && _placeDetails!['user_ratings_total'] != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${_placeDetails!['user_ratings_total']})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_placeDetails != null && _placeDetails!['opening_hours'] != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _placeDetails!['opening_hours']['open_now'] == true
                    ? Icons.check_circle
                    : Icons.cancel,
                  color: _placeDetails!['opening_hours']['open_now'] == true
                    ? Colors.green
                    : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _placeDetails!['opening_hours']['open_now'] == true
                          ? (AppLocalizations.of(context)?.openNow ?? 'Otvoreno')
                          : (AppLocalizations.of(context)?.closedNow ?? 'Zatvoreno'),
                        style: TextStyle(
                          color: _placeDetails!['opening_hours']['open_now'] == true
                            ? Colors.green
                            : Colors.red,
                        ),
                      ),
                      if (_placeDetails!['opening_hours']['weekday_text'] != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showOpeningHours(),
                          child: Text(
                            AppLocalizations.of(context)?.showHours ?? 'Prikaži radno vrijeme',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              decoration: TextDecoration.underline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (widget.place.distance != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF368564), size: 18),
                const SizedBox(width: 8),
                Text(
                  '${widget.place.distance!.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Color(0xFF368564),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Gumb za upute
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMapsDirections(),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: Text(
                AppLocalizations.of(context)?.getDirections ?? 'UPUTE DO LOKACIJE',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFactSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)?.fact ?? 'ČINJENICA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_isLoadingWikipedia || _isLoadingAiFact)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              if (_fact != null && !_isLoadingAiFact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.blue.shade800,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_fact != null)
            Text(
              _fact!,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            )
          else if (!_isLoadingWikipedia && !_isLoadingAiFact)
            Text(
              Localizations.localeOf(context).languageCode == 'hr'
                  ? 'Učitavanje zanimljive činjenice...'
                  : 'Loading interesting fact...',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildWikipediaLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: InkWell(
        onTap: () => _launchWikipediaArticle(),
        child: Row(
          children: [
            Image.asset(
              'assets/images/wikipedia.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.readMoreOnWikipedia ?? 'Pročitaj više na Wikipediji',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _launchWikipediaArticle() async {
    if (_wikipediaInfo == null || _wikipediaInfo!['articleUrl'] == null) return;
    
    final url = Uri.parse(_wikipediaInfo!['articleUrl']!);
    
    try {
      print('Pokušavam otvoriti URL: $url');
      if (await canLaunchUrl(url)) {
        final bool success = await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        
        if (!success) {
          print('Neuspješno otvaranje URL-a: $url');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)?.cannotOpenWikipedia ?? 'Nije moguće otvoriti Wikipedia članak'),
              ),
            );
          }
        } else {
          print('Uspješno pokrenut URL: $url');
        }
      } else {
        print('Nije moguće otvoriti URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.cannotOpenWikipedia ?? 'Nije moguće otvoriti Wikipedia članak'),
            ),
          );
        }
      }
    } catch (e) {
      print('Greška pri otvaranju URL-a: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.cannotOpenWikipedia}: $e'),
          ),
        );
      }
    }
  }
  
  void _showFullDetails() {
    if (_placeDetails == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.place.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_wikipediaInfo != null && _wikipediaInfo!['extract'] != null) ...[
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/wikipedia.png',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.wikipediaInfo ?? 'Informacije s Wikipedije',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _wikipediaInfo!['extract']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (_wikipediaInfo!['articleUrl'] != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _launchWikipediaArticle(),
                          child: Text(
                            AppLocalizations.of(context)?.readMoreOnWikipedia ?? 'Pročitaj više na Wikipediji',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                    ] else if (_placeDetails!['editorial_summary'] != null && 
                        _placeDetails!['editorial_summary']['overview'] != null) ...[
                      Text(
                        _placeDetails!['editorial_summary']['overview'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_placeDetails!['formatted_address'] != null) ...[
                      const Text(
                        'Adresa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _placeDetails!['formatted_address'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_placeDetails!['formatted_phone_number'] != null) ...[
                      const Text(
                        'Telefon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _placeDetails!['formatted_phone_number'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_placeDetails!['website'] != null) ...[
                      const Text(
                        'Web stranica',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _placeDetails!['website'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_placeDetails!['reviews'] != null && 
                        (_placeDetails!['reviews'] as List).isNotEmpty) ...[
                      const Text(
                        'Recenzije',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildReviews(),
                    ],
                    if (_placeDetails!['opening_hours'] != null && 
                        _placeDetails!['opening_hours']['weekday_text'] != null) ...[
                      const Text(
                        'Radno vrijeme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_placeDetails!['opening_hours']['weekday_text'] as List<dynamic>).map((day) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  List<Widget> _buildReviews() {
    final reviews = _placeDetails!['reviews'] as List;
    
    return reviews.take(3).map((review) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (review['profile_photo_url'] != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(review['profile_photo_url']),
                    radius: 16,
                  )
                else
                  const CircleAvatar(
                    child: Icon(Icons.person),
                    radius: 16,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review['author_name'] ?? 'Korisnik',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      review['rating'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['text'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }
  
  void _showOpeningHours() {
    if (_placeDetails == null || _placeDetails!['opening_hours'] == null || 
        _placeDetails!['opening_hours']['weekday_text'] == null) return;
        
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final List<dynamic> weekdayText = _placeDetails!['opening_hours']['weekday_text'];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)?.openingHours ?? 'Radno vrijeme',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...weekdayText.map((dayText) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayText,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)?.close ?? 'Zatvori'),
              ),
            ],
          ),
        );
      },
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
  
  // Metoda za otvaranje Google Maps s uputama
  Future<void> _openGoogleMapsDirections() async {
    final lat = widget.place.location.latitude;
    final lng = widget.place.location.longitude;
    final name = Uri.encodeComponent(widget.place.name);
    
    final urlString = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${widget.place.id}&destination_name=$name';
    final url = Uri.parse(urlString);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.cannotOpenMaps ?? 'Nije moguće otvoriti Google Maps'),
          ),
        );
      }
    }
  }
} 