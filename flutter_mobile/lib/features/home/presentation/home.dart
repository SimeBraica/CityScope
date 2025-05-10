import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobile/features/auth/presentation/pages/login/login.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // 0: Izdvojeno, 1: Mapa, 2: Postavke
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _locationLoading = true;

  static const LatLng zagrebLatLng = LatLng(45.8150, 15.9819);

  @override
  void initState() {
    super.initState();
    _getLocation();
  }


  Future<void> _getLocation() async {
    print('Pokrećem dohvat lokacije (geolocator)...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('Service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentPosition = zagrebLatLng;
          _locationLoading = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    print('Permission: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentPosition = zagrebLatLng;
            _locationLoading = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentPosition = zagrebLatLng;
          _locationLoading = false;
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      print('Dohvaćena lokacija: ${position.latitude}, ${position.longitude}');
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationLoading = false;
        });
      }
    } catch (e) {
      print('Greška kod dohvaćanja lokacije: $e');
      if (mounted) {
        setState(() {
          _currentPosition = zagrebLatLng;
          _locationLoading = false;
        });
      }
    }
  }

  Widget _buildMap() {
    if (_locationLoading || _currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition!,
            zoom: 15,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: const MarkerId('user_location'),
              position: _currentPosition!,
            ),
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 90,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Otvori search.dart
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF368564),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ISTRAŽI PODRUČJE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return _buildMap();
    } else if (_selectedIndex == 0) {
      return const Center(child: Text('Izdvojeno', style: TextStyle(fontSize: 24)));
    } else {
      return const Center(child: Text('Postavke', style: TextStyle(fontSize: 24)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Izdvojeno',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Postavke',
          ),
        ],
        selectedItemColor: Color(0xFF368564),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: const Text('CityScope'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}