import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'catalog_screen.dart';
import 'admin_screen.dart';

// CORS Proxy для зображень Web
String _getProxyImageUrl(String rawUrl) {
  if (kIsWeb && rawUrl.startsWith('http')) {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl)}';
  }
  return rawUrl;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String logoPath = 'images/VHLogo.png';
  final String cartridgeImagePath = 'images/cartridge.jpg';
  final String dropletImagePath = 'images/drop.jpg';
  final String podImagePath = 'images/podsystem.jpg';
  final String bannerImagePath = 'images/chaserforpods.jpg';
  final String accImagePath = 'images/aksesuar.jpg';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Header (Логотип, Адмінка та Пошук) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      logoPath,
                      height: 42,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('V/APE HOUSE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text('економ та не переплачуй', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF7B2CBF), size: 26),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 2. Жива Пошукова Строка ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchQuery.isNotEmpty ? const Color(0xFF7B2CBF) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Пошук товарів, брендів (Chaser), лінійок...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF7B2CBF), size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // --- РОЗГОРТАЛЬНА ПАНЕЛЬ РЕЗУЛЬТАТІВ ПОШУКУ ---
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF7B2CBF)),
                          ),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];

                      List<QueryDocumentSnapshot> matchedDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final brand = (data['brand'] ?? '').toString().toLowerCase();
                        final line = (data['line'] ?? '').toString().toLowerCase();

                        return name.contains(_searchQuery) ||
                            brand.contains(_searchQuery) ||
                            line.contains(_searchQuery);
                      }).toList();

                      matchedDocs.sort((a, b) {
                        final aInStock = (a.data() as Map<String, dynamic>)['inStock'] ?? false;
                        final bInStock = (b.data() as Map<String, dynamic>)['inStock'] ?? false;
                        if (aInStock && !bInStock) return -1;
                        if (!aInStock && bInStock) return 1;
                        return 0;
                      });

                      if (matchedDocs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Нічого не знайдено за вашим запитом',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 340),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2CBF).withOpacity(0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(10),
                              itemCount: matchedDocs.length,
                              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                              itemBuilder: (context, index) {
                                final data = matchedDocs[index].data() as Map<String, dynamic>;
                                final String name = data['name'] ?? '';
                                final String brand = data['brand'] ?? '';
                                final String line = data['line'] ?? '';
                                final String priceStr = '${data['price'] ?? '240'} ₴';
                                final bool inStock = data['inStock'] ?? false;
                                final bool isNew = data['isNew'] ?? false;
                                final String? imgUrl = data['imageUrl'];
                                final String fullName = '$brand $line $name'.trim();

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imgUrl != null && imgUrl.isNotEmpty
                                          ? Image.network(
                                        _getProxyImageUrl(imgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Text('💧', style: TextStyle(fontSize: 20)),
                                        ),
                                      )
                                          : const Center(
                                        child: Text('💧', style: TextStyle(fontSize: 20)),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: TextStyle(
                                            color: inStock ? Colors.white : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isNew) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        inStock ? '● В наявності' : '○ Немає в наявності',
                                        style: TextStyle(
                                          color: inStock ? Colors.greenAccent : Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    priceStr,
                                    style: const TextStyle(
                                      color: Color(0xFF7B2CBF),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          fullName: fullName,
                                          price: priceStr,
                                          imageUrl: imgUrl,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // --- 3. Рекламний Банер ---
                _buildPhotoNeonBanner(context),
                const SizedBox(height: 24),

                // --- 4. Сітка Категорій ---
                const Text('Категорії товарів', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildFullBackgroundCardButton(
                      context,
                      title: 'Рідини',
                      subtitle: 'Смаки, які вражають',
                      imagePath: dropletImagePath,
                      targetScreen: const BrandsScreen(categoryName: 'Рідини'),
                    ),
                    _buildFullBackgroundCardButton(
                      context,
                      title: 'Картриджі',
                      subtitle: 'Оригінальні та сумісні',
                      imagePath: cartridgeImagePath,
                      targetScreen: const CartridgesScreen(),
                    ),
                    _buildFullBackgroundCardButton(
                      context,
                      title: 'Пристрої',
                      subtitle: 'Стиль та потужність',
                      imagePath: podImagePath,
                      targetScreen: const PodsScreen(),
                    ),
                    _buildFullBackgroundCardButton(
                      context,
                      title: 'Аксесуари',
                      subtitle: 'Все для девайсу',
                      imagePath: accImagePath,
                      targetScreen: const AccessoriesScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // --- 5. Популярні товари (Динамічно з Firestore) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Популярні товари', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Всі →', style: TextStyle(color: Color(0xFF7B2CBF), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products').limit(6).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildProductCard('Chaser Виноград', '240 ₴', dropletImagePath, isNew: false),
                            _buildProductCard('Lucky Полуниця', '240 ₴', dropletImagePath, isNew: false),
                            _buildProductCard('XROS 0.6Ω', '130 ₴', cartridgeImagePath, isNew: false),
                          ],
                        );
                      }

                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final String name = data['name'] ?? 'Смак';
                          final String price = '${data['price'] ?? '240'} ₴';
                          final String? img = data['imageUrl'];
                          final bool isNew = data['isNew'] ?? false;

                          return _buildProductCard(
                            name,
                            price,
                            (img != null && img.isNotEmpty) ? img : dropletImagePath,
                            isNew: isNew,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullBackgroundCardButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String imagePath,
        required Widget targetScreen,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF7B2CBF).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imagePath.startsWith('http')
                  ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1A1A)),
              )
                  : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1A1A)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 6,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoNeonBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Positioned.fill(
              child: bannerImagePath.startsWith('http')
                  ? Image.network(
                bannerImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E1E1E)),
              )
                  : Image.asset(
                bannerImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E1E1E)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('НОВІ СМАКИ', style: TextStyle(color: Color(0xFF7B2CBF), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'CHASER FOR PODS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Ще більше яскравих емоцій', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2CBF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FlavorsScreen(
                            categoryName: 'Рідини',
                            brandName: 'Chaser',
                            lineName: 'For Pods',
                          ),
                        ),
                      );
                    },
                    child: const Text('Дивитись', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ВІДЖЕТ: Картка товару з відображенням бейджа NEW ---
  Widget _buildProductCard(String name, String price, String imageUrl, {bool isNew = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                    _getProxyImageUrl(imageUrl),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.blur_on, color: Color(0xFF7B2CBF), size: 30)),
                  )
                      : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.blur_on, color: Color(0xFF7B2CBF), size: 30)),
                  ),
                ),
              ),
              if (isNew)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: Color(0xFF7B2CBF), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('● В наявності', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
        ],
      ),
    );
  }
}