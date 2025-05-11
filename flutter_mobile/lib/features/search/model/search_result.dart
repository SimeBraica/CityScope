import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchResult {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String category;
  final String? subcategory;
  final LatLng location;
  final double? distance; // udaljenost u km
  final double? price; // okvirna cijena u eurima
  final double? rating; // ocjena 1-5
  
  SearchResult({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    this.subcategory,
    required this.location,
    this.distance,
    this.price,
    this.rating,
  });
  
  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
      location: LatLng(
        map['location']['latitude'] ?? 0.0,
        map['location']['longitude'] ?? 0.0,
      ),
      distance: map['distance']?.toDouble(),
      price: map['price']?.toDouble(),
      rating: map['rating']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'subcategory': subcategory,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'distance': distance,
      'price': price,
      'rating': rating,
    };
  }
} 