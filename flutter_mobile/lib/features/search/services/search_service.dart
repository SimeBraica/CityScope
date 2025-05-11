import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobile/features/search/model/search_result.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_mobile/core/env_config.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _apiKey = EnvConfig.googleMapsApiKey;
  String get apiKey => _apiKey;
  
  final Map<String, List<String>> _categoryTypesMap = {
    'food': ['restaurant', 'cafe', 'bar', 'bakery', 'meal_delivery', 'meal_takeaway'],
    'attractions': ['park', 'tourist_attraction', 'amusement_park', 'zoo', 'aquarium'],
    'culture': ['museum', 'art_gallery', 'library', 'church', 'place_of_worship', 'point_of_interest'],
    'music': ['night_club', 'bar', 'movie_theater', 'point_of_interest'],
    'hobbies': ['gym', 'stadium', 'shopping_mall', 'spa', 'store']
  };
  
  Future<List<SearchResult>> searchPlaces({
    required LatLng userLocation,
    required double maxDistance, // u km
    required double maxPrice, // u €
    required Set<String> categories,
    required Map<String, List<String>> userInterests,
    Set<String>? subcategories, 
  }) async {
    if (categories.isEmpty) {
      return [];
    }
    
    List<SearchResult> results = [];
    
    for (final category in categories) {
      var placeTypes = _categoryTypesMap[category] ?? ['point_of_interest'];
      
      if (subcategories != null && subcategories.isNotEmpty) {
        final categorySubcategories = _getCategorySubcategories(category, subcategories);
        if (categorySubcategories.isNotEmpty) {
          placeTypes = categorySubcategories.toList();
        }
      }
      
      final List<String> keywords = [];
      if (userInterests.containsKey(category) && userInterests[category]!.isNotEmpty) {
        keywords.addAll(userInterests[category]!);
      } else {
        keywords.add(category);
      }
      
      for (final type in placeTypes) {
        if (keywords.isNotEmpty) {
          for (final keyword in keywords) {
            final response = await _searchGooglePlaces(
              userLocation: userLocation,
              keyword: keyword,
              type: type,
              radius: maxDistance * 1000, // Google Places koristi metre
            );
            
            results.addAll(response);
          }
        } else {
          final response = await _searchGooglePlaces(
            userLocation: userLocation,
            type: type,
            radius: maxDistance * 1000,
          );
          
          results.addAll(response);
        }
      }
    }
    
    results = results.where((result) {
      return result.price == null || result.price! <= maxPrice;
    }).toList();
    
    final uniqueResults = <String, SearchResult>{};
    for (var result in results) {
      uniqueResults[result.id] = result;
    }
    
    final sortedResults = uniqueResults.values.toList()
      ..sort((a, b) {
        final aDistance = a.distance ?? double.infinity;
        final bDistance = b.distance ?? double.infinity;
        return aDistance.compareTo(bDistance);
      });
    
    return sortedResults;
  }
  
  Future<List<SearchResult>> _searchGooglePlaces({
    required LatLng userLocation,
    String? keyword,
    required String? type,
    required double radius, // u metrima
  }) async {
    final Map<String, String> params = {
      'location': '${userLocation.latitude},${userLocation.longitude}',
      'radius': radius.toString(),
      'key': _apiKey,
    };
    
    if (type == 'asian' || type == 'italian' || type == 'fastfood' || type == 'american' || type == 'indian' || type == 'local') {
      params['type'] = 'restaurant';
      
      if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = '$keyword ${_getTranslatedCuisine(type)}';
      } else {
        params['keyword'] = _getTranslatedCuisine(type);
      }
    } 
    else if (type == 'church' || type == 'place_of_worship') {
      if (type == 'church') {
        params['type'] = 'church';
        params['keyword'] = (keyword != null && keyword.isNotEmpty) 
            ? '$keyword crkva katedrala cathedral' 
            : 'crkva katedrala church cathedral';
        
        params['radius'] = (radius * 1.5).toString();
      } else {
        params['type'] = 'place_of_worship';
        params['keyword'] = (keyword != null && keyword.isNotEmpty) 
            ? '$keyword vjerski objekt crkva sinagoga džamija' 
            : 'vjerski objekt church synagogue mosque';
      }
    }
    else {
      if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = keyword;
      }
      
      if (type != null && type.isNotEmpty) {
        params['type'] = type;
      }
    }
    
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', params);
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> places = data['results'];
          
          return places.map((place) {
            final location = LatLng(
              place['geometry']['location']['lat'],
              place['geometry']['location']['lng'],
            );
            
            final distance = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              location.latitude,
              location.longitude,
            ) / 1000;
            
            double? price;
            if (place['price_level'] != null) {
              // price_level: 0 - besplatno, 1 - jeftino, 2 - umjereno, 3 - skupo, 4 - vrlo skupo
              switch (place['price_level']) {
                case 0: price = 0; break;
                case 1: price = 10; break;
                case 2: price = 30; break;
                case 3: price = 60; break;
                case 4: price = 100; break;
              }
            }
            
            String category = 'food';
            String? subcategory;
            if (place['types'] != null) {
              final types = List<String>.from(place['types']);
              if (types.any((t) => ['park', 'tourist_attraction', 'zoo', 'aquarium'].contains(t))) {
                category = 'attractions';
                if (types.contains('park')) subcategory = 'park';
                else if (types.contains('zoo')) subcategory = 'zoo';
                else if (types.contains('aquarium')) subcategory = 'aquarium';
                else subcategory = 'tourist_attraction';
              } else if (types.any((t) => ['museum', 'art_gallery', 'church', 'place_of_worship'].contains(t))) {
                category = 'culture';
                if (types.contains('church')) subcategory = 'church';
                else if (types.contains('place_of_worship')) subcategory = 'place_of_worship';
                else if (types.contains('museum')) subcategory = 'museum';
                else if (types.contains('art_gallery')) subcategory = 'art_gallery';
                else if (types.contains('library')) subcategory = 'library';
              } else if (types.any((t) => ['night_club', 'concert_hall'].contains(t))) {
                category = 'music';
                if (types.contains('night_club')) subcategory = 'night_club';
                else if (types.contains('movie_theater')) subcategory = 'movie_theater';
              } else if (types.any((t) => ['gym', 'stadium', 'shopping_mall'].contains(t))) {
                category = 'hobbies';
                if (types.contains('gym')) subcategory = 'gym';
                else if (types.contains('stadium')) subcategory = 'stadium';
                else if (types.contains('shopping_mall')) subcategory = 'shopping_mall';
                else if (types.contains('spa')) subcategory = 'spa';
                else subcategory = 'store';
              } else if (types.any((t) => ['restaurant', 'cafe', 'bar', 'bakery'].contains(t))) {
                category = 'food';
                if (types.contains('restaurant')) subcategory = 'restaurant';
                else if (types.contains('cafe')) subcategory = 'cafe';
                else if (types.contains('bar')) subcategory = 'bar';
                else if (types.contains('bakery')) subcategory = 'bakery';
              }
            }
            
            return SearchResult(
              id: place['place_id'],
              name: place['name'],
              description: place['vicinity'],
              imageUrl: place['photos'] != null && place['photos'].isNotEmpty
                  ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=$_apiKey'
                  : null,
              category: category,
              subcategory: subcategory,
              location: location,
              distance: distance,
              price: price,
              rating: place['rating']?.toDouble(),
            );
          }).toList();
        }
      }
      
      print('Google Places API greška: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Greška pri pozivu Google Places API: $e');
      return [];
    }
  }
  
  String _getTranslatedCuisine(String? cuisineType) {
    switch (cuisineType) {
      case 'asian':
        return 'asian chinese japanese thai vietnamese sushi ramen';
      case 'italian':
        return 'italian pizza pasta';
      case 'fastfood':
        return 'fast food burger mcdonalds kfc';
      case 'american':
        return 'american burger mcdonalds kfc';
      case 'indian':
        return 'indian curry tandoori butten chicken';
      case 'local':
        return 'local traditional croatian domaća kuhinja specijaliteti lokalna hrana gdje lokalci jedu';
      default:
        return cuisineType ?? '';
    }
  }
  
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'name,rating,formatted_phone_number,website,opening_hours,price_level,editorial_summary,photos,vicinity,formatted_address,reviews',
      'key': _apiKey,
    });
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      
      print('Google Places Details API greška: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Greška pri pozivu Google Places Details API: $e');
      return null;
    }
  }
  
  Future<void> saveSearchHistory(List<SearchResult> results, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final searchHistoryRef = _firestore.collection('users').doc(userId).collection('searchHistory');
      
      for (int i = 0; i < results.length && i < 10; i++) {
        final result = results[i];
        
        batch.set(
          searchHistoryRef.doc(result.id),
          {
            ...result.toMap(),
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }
      
      await batch.commit();
    } catch (e) {
      print('Greška pri spremanju povijesti pretrage: $e');
    }
  }

  Future<Map<String, String?>> getWikipediaInfo(String placeName, String language) async {
    final String wikipediaLang = language == 'hr' ? 'hr' : 'en';
    
    String searchName = placeName;
    List<String> simplifiedNames = [searchName];
    
    print('Pretraga Wikipedije za "$placeName" (jezik: $wikipediaLang)');
    
    if (placeName.toLowerCase().contains('zagreb') && 
        (placeName.toLowerCase().contains('katedrala') || placeName.toLowerCase().contains('cathedral'))) {
      if (wikipediaLang == 'hr') {
        simplifiedNames.addAll([
          'Zagrebačka katedrala',
          'Katedrala Uznesenja Blažene Djevice Marije i svetih Stjepana i Ladislava',
          'Katedrala Zagreb'
        ]);
      } else {
        simplifiedNames.addAll([
          'Zagreb Cathedral', 
          'Cathedral of Zagreb',
          'Cathedral of the Assumption of the Blessed Virgin Mary'
        ]);
      }
    }
    
    if (isCulturalPlace(placeName)) {
      final prefixPattern = RegExp(r'^(crkva|katedrala|bazilika|muzej|galerija|museum|cathedral|basilica|gallery|church)\s+',
          caseSensitive: false);
      if (prefixPattern.hasMatch(placeName.toLowerCase())) {
        final withoutPrefix = placeName.replaceFirst(prefixPattern, '');
        simplifiedNames.add(withoutPrefix);
      }
      
      if (placeName.toLowerCase().contains('mark') || placeName.toLowerCase().contains('marc')) {
        if (wikipediaLang == 'hr' && !placeName.toLowerCase().contains('crkva')) {
          simplifiedNames.add('Crkva svetog Marka');
        } else if (wikipediaLang == 'en' && !placeName.toLowerCase().contains('church')) {
          simplifiedNames.add('Saint Mark\'s Church');
        }
      }
      
      if (placeName.toLowerCase().contains('kated') || placeName.toLowerCase().contains('cathe')) {
        if (wikipediaLang == 'hr' && !placeName.toLowerCase().contains('katedrala')) {
          simplifiedNames.add('Katedrala $placeName');
        } else if (wikipediaLang == 'en' && !placeName.toLowerCase().contains('cathedral')) {
          simplifiedNames.add('Cathedral of $placeName');
          simplifiedNames.add('$placeName Cathedral');
        }
      }
      
      if (placeName.toLowerCase().contains('muze') || placeName.toLowerCase().contains('museum')) {
        if (wikipediaLang == 'hr' && !placeName.toLowerCase().contains('muzej')) {
          simplifiedNames.add('Muzej $placeName');
        } else if (wikipediaLang == 'en' && !placeName.toLowerCase().contains('museum')) {
          simplifiedNames.add('$placeName Museum');
          simplifiedNames.add('Museum of $placeName');
        }
      }
    }
    
    simplifiedNames = simplifiedNames.toSet().toList();
    
    print('Varijante naziva za pretragu: $simplifiedNames');
    
    for (final name in simplifiedNames) {
      try {
        final Uri uri = Uri.https('$wikipediaLang.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'prop': 'extracts|pageimages|info',
          'exintro': 'true',
          'explaintext': 'true',
          'titles': name,
          'piprop': 'original',
          'inprop': 'url',
        });
        
        final response = await http.get(uri);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final pages = data['query']['pages'];
          
          if (pages != null) {
            final String firstPageId = pages.keys.first;
            
            if (firstPageId != "-1") {
              final page = pages[firstPageId];
              print('Pronađen Wikipedia članak za naziv "$name": ${page['title']}');
              return {
                'title': page['title'],
                'extract': page['extract'],
                'imageUrl': page['original']?['source'],
                'articleUrl': page['fullurl'],
              };
            }
          }
        }
      } catch (e) {
        print('Greška pri pozivu Wikipedia API-ja za naziv "$name": $e');
      }
    }
    
    print('Wikipedia API nije pronašao rezultate za naziv "$placeName" ni za jednu od varijanti');
    return {'error': 'Podaci nisu dostupni'};
  }
  
  bool isCulturalPlace(String name) {
    final String lowerName = name.toLowerCase();
    
    return lowerName.contains('crkva') || 
           lowerName.contains('church') ||
           lowerName.contains('katedrala') ||
           lowerName.contains('cathedral') ||
           lowerName.contains('bazilika') ||
           lowerName.contains('basilica') ||
           lowerName.contains('muzej') ||
           lowerName.contains('museum') ||
           lowerName.contains('galerija') ||
           lowerName.contains('gallery') ||
           lowerName.contains('knjižnica') ||
           lowerName.contains('library');
  }

  Set<String> _getCategorySubcategories(String category, Set<String> subcategories) {
    final Set<String> result = {};
    
    for (final subcategory in subcategories) {
      if (category == 'food') {
        if(['restaurant', 'cafe', 'bar', 'bakery', 'meal_delivery', 'meal_takeaway'].contains(subcategory) ||
           ['asian', 'italian', 'fastfood', 'american', 'indian', 'local'].contains(subcategory)) {
          result.add(subcategory);
        }
      } else if (category == 'attractions') {
        if(['park', 'tourist_attraction', 'amusement_park', 'zoo', 'aquarium'].contains(subcategory)) {
          result.add(subcategory);
        }
      } else if (category == 'culture') {
        if(['museum', 'art_gallery', 'library', 'church', 'place_of_worship'].contains(subcategory)) {
          result.add(subcategory);
        }
      } else if (category == 'music') {
        if(['night_club', 'bar', 'movie_theater'].contains(subcategory)) {
          result.add(subcategory);
        }
      } else if (category == 'hobbies') {
        if(['gym', 'stadium', 'shopping_mall', 'spa', 'store'].contains(subcategory)) {
          result.add(subcategory);
        }
      }
    }
    
    return result;
  }

  Future<String> getAiFunFact(String placeName, String? category, String? subcategory, Map<String, String?>? wikipediaInfo, Map<String, dynamic>? placeDetails, String languageCode) async {
    try {
      String promptBase = languageCode == 'hr' 
        ? "Generiraj kratku zanimljivu činjenicu (jedna rečenica) o mjestu: $placeName. Maksimalno 150 znakova. ODGOVORI ISKLJUČIVO NA HRVATSKOM JEZIKU."
        : "Generate a short one sentence fun fact about $placeName. Maximum 150 characters. ANSWER IN ENGLISH ONLY.";
      
      // TODO: ako nađem bolji model poslati i ovo
      // if (category != null) {
      //   promptBase += languageCode == 'hr' 
      //     ? " Kategorija: $category." 
      //     : " Category: $category.";
      // }
      
      // if (subcategory != null) {
      //   promptBase += languageCode == 'hr' 
      //     ? " Potkategorija: $subcategory." 
      //     : " Subcategory: $subcategory.";
      // }
      
      // if (wikipediaInfo != null && wikipediaInfo['extract'] != null) {
      //   promptBase += languageCode == 'hr' 
      //     ? " Informacije: ${wikipediaInfo['extract']}" 
      //     : " Information: ${wikipediaInfo['extract']}";
      // }
      
      // if (placeDetails != null && placeDetails['editorial_summary'] != null && placeDetails['editorial_summary']['overview'] != null) {
      //   promptBase += languageCode == 'hr' 
      //     ? " Dodatne informacije: ${placeDetails['editorial_summary']['overview']}" 
      //     : " Additional information: ${placeDetails['editorial_summary']['overview']}";
      // }
      
      print('AI prompt: $promptBase');
      
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/meta-llama/Llama-3.1-8B-Instruct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${EnvConfig.huggingFaceApiKey}',
        },
        body: jsonEncode({
          'inputs': promptBase,
          'parameters': {
            'max_new_tokens': 150,
            'temperature': 0.9,
            'top_p': 0.95,
            'return_full_text': false
          }
        }),
      );
      
      print('AI API odgovor status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final String responseBody = response.body;
        print('AI API odgovor tijelo: $responseBody');
        
        try {
          final jsonResponse = jsonDecode(responseBody);
          
          String funFact = "";
          
          if (jsonResponse is List && jsonResponse.isNotEmpty) {
            if (jsonResponse[0] is Map && jsonResponse[0].containsKey('generated_text')) {
              funFact = jsonResponse[0]['generated_text'] ?? '';
            } else if (jsonResponse[0] is String) {
              funFact = jsonResponse[0];
            }
          } else if (jsonResponse is Map) {
            if (jsonResponse.containsKey('generated_text')) {
              funFact = jsonResponse['generated_text'] ?? '';
            }
          }
          
          funFact = funFact.trim();
          
          if (languageCode == 'hr') {
            final RegExp hrPattern = RegExp(r'(?:[A-ZŠĐČĆŽ][a-zšđčćž\d\s,.!?:;]+?[.!?])');
            final Iterable<RegExpMatch> matches = hrPattern.allMatches(funFact);
            
            if (matches.isNotEmpty) {
              String bestMatch = '';
              for (var match in matches) {
                String candidate = match.group(0) ?? '';
                if (candidate.length > bestMatch.length && 
                    (candidate.contains('č') || candidate.contains('ć') || 
                     candidate.contains('ž') || candidate.contains('š') || 
                     candidate.contains('đ'))) {
                  bestMatch = candidate;
                }
              }
              
              if (bestMatch.isNotEmpty) {
                funFact = bestMatch;
              }
            }
          } else {
            final RegExp enPattern = RegExp(r'(?:fact about [^:.]*:?\s*)([A-Z][^.]*\.)');
            final match = enPattern.firstMatch(funFact);
            if (match != null && match.groupCount >= 1) {
              funFact = match.group(1) ?? funFact;
            }
          }
          
          final promptWords = promptBase.split(' ').where((word) => word.length > 5).toList();
          for (final word in promptWords) {
            if (funFact.startsWith(word)) {
              final index = funFact.indexOf('.');
              if (index > 0) {
                funFact = funFact.substring(index + 1).trim();
              }
              break;
            }
          }
          
          final responsePattern = RegExp(r'^\s*(AI|Assistant|Model):\s*', caseSensitive: false);
          funFact = funFact.replaceFirst(responsePattern, '');
          
          final RegExp backToPattern = RegExp(r'Back to (answers|questions)');
          final backMatch = backToPattern.firstMatch(funFact);
          if (backMatch != null) {
            funFact = funFact.substring(0, backMatch.start).trim();
          }
          
          if (funFact.contains("Translation:")) {
            funFact = funFact.substring(0, funFact.indexOf("Translation:")).trim();
          }
          
          print('Obrađeni AI odgovor: "$funFact"');
          
          if (funFact.isEmpty) {
            print('Odgovor je prazan vraćamo zadani tekst.');
            return _getDefaultFact(placeName, category, subcategory, languageCode);
          }
          
          return funFact;
        } catch (e) {
          print('Greška pri parsiranju JSON odgovora: $e');
          return _getDefaultFact(placeName, category, subcategory, languageCode);
        }
      } else {
        print('Greška pri generiranju AI činjenice: ${response.statusCode}, odgovor: ${response.body}');
        return _getDefaultFact(placeName, category, subcategory, languageCode);
      }
    } catch (e) {
      print('Iznimka pri generiranju AI činjenice: $e');
      return _getDefaultFact(placeName, category, subcategory, languageCode);
    }
  }
  
  String _getDefaultFact(String placeName, String? category, String? subcategory, String languageCode) {
    if (languageCode == 'hr') {
      if (category == 'culture' || category == 'attractions') {
        if (subcategory == 'church' || subcategory == 'place_of_worship') {
          return "Značajan sakralni objekt u hrvatskoj kulturnoj baštini";
        } else if (subcategory == 'museum') {
          return "Muzej s vrijednom zbirkom eksponata koji predstavljaju kulturnu baštinu";
        } else if (subcategory == 'art_gallery') {
          return "Galerija koja predstavlja važna umjetnička djela hrvatskih i stranih autora";
        } else {
          return "Značajan objekt hrvatske kulturne baštine";
        }
      } else {
        return "Zanimljiva lokacija u Hrvatskoj vrijedna posjeta";
      }
    } else {
      // Engleske verzije
      if (category == 'culture' || category == 'attractions') {
        if (subcategory == 'church' || subcategory == 'place_of_worship') {
          return "Significant religious site in Croatian cultural heritage";
        } else if (subcategory == 'museum') {
          return "Museum with a valuable collection of exhibits representing cultural heritage";
        } else if (subcategory == 'art_gallery') {
          return "Gallery presenting important artworks by Croatian and international artists";
        } else {
          return "Significant site in Croatian cultural heritage";
        }
      } else {
        return "An interesting location in Croatia worth visiting";
      }
    }
  }
} 