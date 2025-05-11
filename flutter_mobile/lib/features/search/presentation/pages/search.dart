import 'package:carousel_slider/carousel_slider.dart';  
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobile/features/search/model/search_result.dart';
import 'package:flutter_mobile/features/search/services/search_service.dart';
import 'package:flutter_mobile/features/search/presentation/pages/search_results.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'RESTORANI I KAFIĆI',
      'en_name': 'RESTAURANTS & CAFES',
      'image': 'assets/images/search/restaurants.jpg',
      'type': 'food'
    },
    {
      'name': 'PARKOVI',
      'en_name': 'PARKS',
      'image': 'assets/images/search/parks.jpg',
      'type': 'attractions'
    },
    {
      'name': 'KULTURA',
      'en_name': 'CULTURE',
      'image': 'assets/images/search/culture.jpg',
      'type': 'culture'
    },
    {
      'name': 'GLAZBA',
      'en_name': 'MUSIC',
      'image': 'assets/images/search/music.jpg',
      'type': 'music'
    },
    {
      'name': 'HOBIJI',
      'en_name': 'HOBBIES',
      'image': 'assets/images/search/hobbies.jpg',
      'type': 'hobbies'
    },
  ];

  final Map<String, List<Map<String, String>>> _subcategories = {
    'food': [
      {'id': 'restaurant', 'name': 'Restorani', 'en_name': 'Restaurants'},
      {'id': 'cafe', 'name': 'Kafići', 'en_name': 'Cafes'},
      {'id': 'bar', 'name': 'Barovi', 'en_name': 'Bars'},
      {'id': 'bakery', 'name': 'Pekare', 'en_name': 'Bakeries'},
      {'id': 'asian', 'name': 'Azijska', 'en_name': 'Asian'},
      {'id': 'italian', 'name': 'Talijanska', 'en_name': 'Italian'},
      {'id': 'fastfood', 'name': 'Brza hrana', 'en_name': 'Fast Food'},
    ],
    'attractions': [
      {'id': 'park', 'name': 'Parkovi', 'en_name': 'Parks'},
      {'id': 'tourist_attraction', 'name': 'Atrakcije', 'en_name': 'Attractions'},
      {'id': 'zoo', 'name': 'Zoološki', 'en_name': 'Zoo'},
      {'id': 'aquarium', 'name': 'Akvarij', 'en_name': 'Aquarium'},
    ],
    'culture': [
      {'id': 'museum', 'name': 'Muzeji', 'en_name': 'Museums'},
      {'id': 'art_gallery', 'name': 'Galerije', 'en_name': 'Art Galleries'},
      {'id': 'church', 'name': 'Crkve', 'en_name': 'Churches'},
      {'id': 'library', 'name': 'Knjižnice', 'en_name': 'Libraries'},
      {'id': 'place_of_worship', 'name': 'Vjerski objekti', 'en_name': 'Places of Worship'},
    ],
    'music': [
      {'id': 'night_club', 'name': 'Klubovi', 'en_name': 'Night Clubs'},
      {'id': 'bar', 'name': 'Barovi', 'en_name': 'Bars'},
      {'id': 'concert_hall', 'name': 'Koncertne dvorane', 'en_name': 'Concert Halls'},
      {'id': 'movie_theater', 'name': 'Kina', 'en_name': 'Movie Theaters'},
    ],
    'hobbies': [
      {'id': 'gym', 'name': 'Teretane', 'en_name': 'Gyms'},
      {'id': 'stadium', 'name': 'Stadioni', 'en_name': 'Stadiums'},
      {'id': 'shopping_mall', 'name': 'Trgovački centri', 'en_name': 'Shopping Malls'},
      {'id': 'spa', 'name': 'Spa centri', 'en_name': 'Spa'},
      {'id': 'store', 'name': 'Trgovine', 'en_name': 'Stores'},
    ],
  };

  double _distanceValue = 1.0; 
  double _costValue = 10.0; 
  Set<String> _selectedCategories = {};
  Set<String> _selectedSubcategories = {};
  
  Map<String, List<String>> _userInterests = {};
  bool _isLoading = true;
  bool _isSearching = false;
  LatLng? _userLocation;
  
  final SearchService _searchService = SearchService();

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadUserInterests();
  }
  
  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _userLocation = const LatLng(45.8150, 15.9819); 
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _userLocation = const LatLng(45.8150, 15.9819); 
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = const LatLng(45.8150, 15.9819);
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Greška kod dohvaćanja lokacije: $e');
      setState(() {
        _userLocation = const LatLng(45.8150, 15.9819); 
      });
    }
  }

  Future<void> _loadUserInterests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          
          final Map<String, List<String>> interests = {};
          
          if (data['music'] != null) {
            interests['music'] = List<String>.from(data['music']);
          }
          
          if (data['food'] != null) {
            interests['food'] = List<String>.from(data['food']);
          }
          
          if (data['attractions'] != null) {
            interests['attractions'] = List<String>.from(data['attractions']);
          }
          
          if (data['culture'] != null) {
            interests['culture'] = List<String>.from(data['culture']);
          }
          
          if (data['hobbies'] != null) {
            interests['hobbies'] = List<String>.from(data['hobbies']);
          }
          
          setState(() {
            _userInterests = interests;
          });
        }
      }
    } catch (e) {
      print('Greška pri učitavanju interesa: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String type) {
    setState(() {
      if (_selectedCategories.contains(type)) {
        _selectedCategories.remove(type);
        _selectedSubcategories.removeWhere((subcategory) => 
          _subcategories[type]?.any((sub) => sub['id'] == subcategory) ?? false);
      } else {
        _selectedCategories.add(type);
      }
    });
  }

  void _onSubcategorySelected(String subcategoryId) {
    setState(() {
      if (_selectedSubcategories.contains(subcategoryId)) {
        _selectedSubcategories.remove(subcategoryId);
      } else {
        _selectedSubcategories.add(subcategoryId);
      }
    });
  }

  Future<void> _search() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.locationNotAvailable ?? 'Lokacija nije dostupna')),
      );
      return;
    }
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.selectCategory ?? 'Odaberite barem jednu kategoriju')),
      );
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _searchService.searchPlaces(
        userLocation: _userLocation!,
        maxDistance: _distanceValue,
        maxPrice: _costValue,
        categories: _selectedCategories,
        subcategories: _selectedSubcategories,
        userInterests: _userInterests,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && results.isNotEmpty) {
        await _searchService.saveSearchHistory(results, user.uid);
      }
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsPage(
              results: results,
              userLocation: _userLocation!,
            ),
          ),
        );
      }
    } catch (e) {
      print('Greška prilikom pretrage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.searchError ?? 'Pogreška prilikom pretrage')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.whatToDoToday ?? 'Što mi se danas radi?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 180,
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 180,
                        viewportFraction: 0.8,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: true,
                      ),
                      items: _categories.map((category) {
                        final isSelected = _selectedCategories.contains(category['type']);
                        
                        return GestureDetector(
                          onTap: () => _onCategorySelected(category['type']),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  category['image'],
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    Localizations.localeOf(context).languageCode == 'hr' 
                                      ? category['name'] 
                                      : category['en_name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF368564),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  if (_selectedCategories.isNotEmpty)
                    _buildSubcategories(),
                    
                  const SizedBox(height: 32),
                  
                  Text(
                    loc.distanceFromCurrentLocation ?? 'Udaljenost od trenutne lokacije?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF368564),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF368564),
                            overlayColor: const Color(0xFF368564).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _distanceValue,
                            min: 0.5,
                            max: 5.0,
                            divisions: 9,
                            onChanged: (value) {
                              setState(() {
                                _distanceValue = value;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '< ${_distanceValue.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    loc.costs ?? 'Troškovi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF368564),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF368564),
                            overlayColor: const Color(0xFF368564).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _costValue,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                _costValue = value;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '< ${_costValue.toInt()} €',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF368564),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              loc.search ?? 'Istraži',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildSubcategories() {
    final List<Widget> subcategoryWidgets = [];
    
    for (final categoryType in _selectedCategories) {
      final subcategoryList = _subcategories[categoryType] ?? [];
      if (subcategoryList.isNotEmpty) {
        subcategoryWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Text(
              _getCategoryName(categoryType),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        );
        
        subcategoryWidgets.add(
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: subcategoryList.map((subcategory) {
              final isSelected = _selectedSubcategories.contains(subcategory['id']);
              final isCurrentLocale = Localizations.localeOf(context).languageCode == 'hr';
              final displayName = isCurrentLocale ? subcategory['name']! : subcategory['en_name']!;
              
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                selectedColor: const Color(0xFF368564).withOpacity(0.2),
                checkmarkColor: const Color(0xFF368564),
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF368564) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (bool selected) {
                  _onSubcategorySelected(subcategory['id']!);
                },
              );
            }).toList(),
          ),
        );
      }
    }
    
    return subcategoryWidgets.isEmpty 
      ? const SizedBox.shrink() 
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subcategoryWidgets,
        );
  }
  
  String _getCategoryName(String type) {
    final isCurrentLocale = Localizations.localeOf(context).languageCode == 'hr';
    final categoryMap = _categories.firstWhere(
      (category) => category['type'] == type,
      orElse: () => {'name': type, 'en_name': type},
    );
    
    return isCurrentLocale ? categoryMap['name'] : categoryMap['en_name'];
  }
}
