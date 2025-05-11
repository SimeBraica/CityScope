import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Map<String, String> _defaultValues = {
    'GOOGLE_MAPS_API_KEY': 'AIzaSyAk8EgixUGGwE2U6d3-COqq7jtxP1Uxk3U',
    'HUGGINGFACE_API_KEY': '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',
  };
  
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      print("Uspješno učitana .env datoteka");
    } catch (e) {
      print("Pogreška pri učitavanju .env datoteke: $e");
      _setDefaultValues();
    }
  }
  
  static void _setDefaultValues() {
    _defaultValues.forEach((key, value) {
      if (dotenv.env[key] == null) {
        dotenv.env[key] = value;
      }
    });
  }
  
  static String get(String key) {
    return dotenv.env[key] ?? _defaultValues[key] ?? '';
  }
  
  static String get googleMapsApiKey => get('GOOGLE_MAPS_API_KEY');
  
  static String get huggingFaceApiKey => get('HUGGINGFACE_API_KEY');
} 