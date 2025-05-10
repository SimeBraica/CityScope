import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AttractionsPage extends StatefulWidget {
  const AttractionsPage({Key? key}) : super(key: key);

  @override
  State<AttractionsPage> createState() => _AttractionsPageState();
}

class _AttractionsPageState extends State<AttractionsPage> {
  List<DocumentSnapshot> _attractions = [];
  Set<String> _favorites = {};
  bool _loading = true;

  final Map<String, String> _attractionImages = {
    'Spomenici': 'assets/images/attraction/monuments.jpg',
    'Povijesne građevine': 'assets/images/attraction/historical_sites.jpg',
  };

  @override
  void initState() {
    super.initState();
    _fetchAttractions();
    _fetchFavorites();
  }

  Future<void> _fetchAttractions() async {
    final snap = await FirebaseFirestore.instance.collection('attraction').get();
    setState(() {
      _attractions = snap.docs;
      _loading = false;
    });
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final favs = userDoc.data()?['attraction'] ?? [];
      setState(() {
        _favorites = Set<String>.from(favs);
      });
    }
  }

  Future<void> _addToFavorites(String attractionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.add(attractionId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'attraction': _favorites.toList(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _removeFromFavorites(String attractionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.remove(attractionId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'attraction': _favorites.toList(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final availableAttractions = _attractions
        .where((g) => !_favorites.contains(g.id))
        .where((g) {
          final data = g.data() as Map<String, dynamic>;
          return (data['name'] != null && (data['name'] as String).trim().isNotEmpty);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.interestAttractions ?? 'Znamenitosti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF368564),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (availableAttractions.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                  ),
                  items: availableAttractions.map((attraction) {
                    final data = attraction.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final img = _attractionImages[name];
                    return SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: img != null
                                ? Image.asset(
                                    img,
                                    width: 180,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 180,
                                    height: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.location_on, size: 60, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name.toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () => _addToFavorites(attraction.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF368564),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                            ),
                            child: Text(loc.addToFavorites ?? 'DODAJ U OMILJENE', style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(loc.allAttractionsSelected ?? 'Odabrane su sve znamenitosti.'),
                ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.favorites ?? 'Favoriti',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF484751)),
                ),
              ),
              const SizedBox(height: 12),
              _favorites.isEmpty
                  ? Text(loc.noFavorites ?? 'Nema favorita.')
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: _favorites
                          .where((attractionId) => _attractions.any((g) => g.id == attractionId))
                          .map((attractionId) {
                        final attraction = _attractions.firstWhere((g) => g.id == attractionId);
                        final data = attraction.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF368564).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFF368564), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF368564),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _removeFromFavorites(attractionId),
                                child: const Icon(Icons.close, size: 16, color: Color(0xFF368564)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}