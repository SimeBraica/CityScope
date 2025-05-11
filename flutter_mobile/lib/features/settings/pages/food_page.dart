import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({Key? key}) : super(key: key);

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  List<DocumentSnapshot> _items = [];
  Set<String> _favorites = {};
  bool _loading = true;
  final Map<String, String> _foodImages = {
    'Talijanska': 'assets/images/food/italian.jpg',
    'Indijska': 'assets/images/food/indian.jpg',
    'Azijska': 'assets/images/food/asian.jpg',
    'Američka': 'assets/images/food/american.jpg',
    'Lokalna': 'assets/images/food/local.jpg',
  };

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchFavorites();
  }

  Future<void> _fetchItems() async {
    final snap = await FirebaseFirestore.instance.collection('food').get();
    setState(() {
      _items = snap.docs;
      _loading = false;
    });
  }

  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final favs = userDoc.data()?['food'] ?? [];
      setState(() {
        _favorites = Set<String>.from(favs);
      });
    }
  }

  Future<void> _addToFavorites(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.add(itemId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'food': _favorites.toList(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _removeFromFavorites(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _favorites.remove(itemId);
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'food': _favorites.toList(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final availableItems = _items
        .where((g) => !_favorites.contains(g.id))
        .where((g) {
          final data = g.data() as Map<String, dynamic>;
          return (data['name'] != null && (data['name'] as String).trim().isNotEmpty);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.interestsFood, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              if (availableItems.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 350,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                  ),
                  items: availableItems.map((item) {
                    final data = item.data() as Map<String, dynamic>;
                    final name = locale == 'hr' ? data['name'] : data['en'];
                    final desc = data['description'] ?? '';
                    final img = _foodImages[data['name']];
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
                                    child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
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
                          if (locale == 'hr')
                            Text(
                              desc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () => _addToFavorites(item.id),
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
                  child: Text(loc.allFoodSelected ?? 'Odabrane su sve kuhinje.'),
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
                          .where((itemId) => _items.any((g) => g.id == itemId))
                          .map((itemId) {
                        final item = _items.firstWhere((g) => g.id == itemId);
                        final data = item.data() as Map<String, dynamic>;
                        final name = locale == 'hr' ? data['name'] : data['en'];
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
                                onTap: () => _removeFromFavorites(itemId),
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