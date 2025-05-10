import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CulturePage extends StatefulWidget {
  const CulturePage({Key? key}) : super(key: key);

  @override
  State<CulturePage> createState() => _CulturePageState();
}

class _CulturePageState extends State<CulturePage> {
  List<DocumentSnapshot> _cultures = [];
  Set<String> _favorites = {};
  bool _loading = true;

  final Map<String, String> _cultureImages = {
    'Kazalište': 'assets/images/culture/theatre.jpg',
    'Kino': 'assets/images/culture/cinema.jpg',
    'Koncert': 'assets/images/culture/concert.jpg',
    'Muzeji i galerije': 'assets/images/culture/museum.jpg',
  };

  @override
  void initState() {
    super.initState();
    _fetchCultures();
    _fetchFavorites();
  }

  Future<void> _fetchCultures() async {
    final snap = await FirebaseFirestore.instance.collection('culture').get();
    setState(() {
      _cultures = snap.docs;
      _loading = false;
    });
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final favs = userDoc.data()?['culture'] ?? [];
      setState(() {
        _favorites = Set<String>.from(favs);
      });
    }
  }

  Future<void> _addToFavorites(String cultureId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.add(cultureId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'culture': _favorites.toList(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _removeFromFavorites(String cultureId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.remove(cultureId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'culture': _favorites.toList(),
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

    final availableCultures = _cultures
        .where((g) => !_favorites.contains(g.id))
        .where((g) {
          final data = g.data() as Map<String, dynamic>;
          return (data['name'] != null && (data['name'] as String).trim().isNotEmpty);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.interestsCulture ?? 'Kultura', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              if (availableCultures.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 350,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                  ),
                  items: availableCultures.map((culture) {
                    final data = culture.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final desc = data['description'] ?? '';
                    final img = _cultureImages[name];
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
                                    height: 140,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 180,
                                    height: 140,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.theater_comedy, size: 60, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name.toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () => _addToFavorites(culture.id),
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
                  child: Text(loc.allCulturesSelected ?? 'Odabrane su sve kulturološke lokacije.'),
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
                          .where((cultureId) => _cultures.any((g) => g.id == cultureId))
                          .map((cultureId) {
                        final culture = _cultures.firstWhere((g) => g.id == cultureId);
                        final data = culture.data() as Map<String, dynamic>;
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
                                onTap: () => _removeFromFavorites(cultureId),
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