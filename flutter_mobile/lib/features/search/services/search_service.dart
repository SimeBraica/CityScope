import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mobile/features/search/model/search_result.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _apiKey = 'AIzaSyAk8EgixUGGwE2U6d3-COqq7jtxP1Uxk3U';
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
        return 'asian chinese japanese thai vietnamese';
      case 'italian':
        return 'italian pizza pasta';
      case 'fastfood':
        return 'fast food burger mcdonalds kfc';
      case 'american':
        return 'american burger mcdonalds kfc';
      case 'indian':
        return 'indian curry tandoori';
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
} 