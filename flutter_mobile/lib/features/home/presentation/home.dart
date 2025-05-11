import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobile/features/auth/presentation/pages/login/login.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_mobile/features/settings/pages/settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobile/features/search/presentation/pages/search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 1; 
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _locationLoading = true;
  
  Set<Marker> _markers = {};
  Timer? _locationTimer;

  static const LatLng zagrebLatLng = LatLng(45.8150, 15.9819);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getLocation();
    
    _locationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_selectedIndex == 1) {
        _getLocation();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedIndex == 1) {
      _getLocation();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedIndex == 1) {
      _getLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    if (!mounted) return;
    
    setState(() {
      _locationLoading = true;
    });
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentPosition = zagrebLatLng;
          _locationLoading = false;
          _setUserLocationMarker();
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentPosition = zagrebLatLng;
            _locationLoading = false;
            _setUserLocationMarker();
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
          _setUserLocationMarker();
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationLoading = false;
          _setUserLocationMarker();
        });
      }
    } catch (e) {
      print('Greška kod dohvaćanja lokacije: $e');
      if (mounted) {
        setState(() {
          _currentPosition = zagrebLatLng;
          _locationLoading = false;
          _setUserLocationMarker();
        });
      }
    }
  }
  
  void _setUserLocationMarker() {
    if (_currentPosition == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: AppLocalizations.of(context)?.yourLocation ?? 'Vaša lokacija',
          ),
        ),
      };
    });
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
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _markers,
        ),
        
        Positioned(
          left: 0,
          right: 0,
          bottom: 90,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF368564),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.exploreArea, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return _buildMap();
    } else {
      return const SettingsPage();
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
          
          if (index == 1) {
            _getLocation();
          }
        },
        items: [

          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: AppLocalizations.of(context)!.map,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        selectedItemColor: const Color(0xFF368564),
        backgroundColor: Colors.white,
      ),
    );
  }
}