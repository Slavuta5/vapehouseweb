import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_manager.dart';

// Хелпер для обходу CORS Web у каталозі
String _getProxyImageUrl(String rawUrl) {
  if (kIsWeb && rawUrl.startsWith('http')) {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl)}';
  }
  return rawUrl;
}

// Хелпер для виклику сучасного неонового SnackBar
void _showModernSnackBar(BuildContext context, String text, {IconData icon = Icons.check_circle_outline_rounded}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7B2CBF).withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2CBF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF9D4EDD), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- Екран 2: Головний Каталог ---
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Каталог',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListView(
          children: [
            _buildHorizontalCatalogButton(
              context,
              title: 'Рідини',
              subtitle: 'Бренди, лінійки, смаки',
              icon: '💧',
              targetScreen: const BrandsScreen(categoryName: 'Рідини'),
            ),
            _buildHorizontalCatalogButton(
              context,
              title: 'Картриджі',
              subtitle: 'Сумісність, опір, моделі',
              icon: '🔌',
              targetScreen: const CartridgesScreen(),
            ),
            _buildHorizontalCatalogButton(
              context,
              title: 'Пристрої',
              subtitle: 'Пристрої та комплектація',
              icon: '🔋',
              targetScreen: const PodsScreen(),
            ),
            _buildHorizontalCatalogButton(
              context,
              title: 'Аксесуари',
              subtitle: 'Ватка, випарники, чохли',
              icon: '⚙️',
              targetScreen: const AccessoriesScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCatalogButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String icon,
        required Widget targetScreen,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7B2CBF).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF7B2CBF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Екран 3: Вибір Бренду ---
class BrandsScreen extends StatelessWidget {
  final String categoryName;
  const BrandsScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Каталог / $categoryName', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const Text('Преміальні бренди', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildBrandNeonCard(context, name: 'Chaser', desc: 'Яскраві моно-смаки та насичені мікси', icon: '⚡'),
            _buildBrandNeonCard(context, name: 'Lucky', desc: 'Український бренд преміум якості', icon: '🍀'),
            _buildBrandNeonCard(context, name: 'Hype', desc: 'Сміливі поєднання з льодом', icon: '🔥'),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandNeonCard(BuildContext context, {required String name, required String desc, required String icon}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LinesScreen(brandName: name, categoryName: categoryName)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF7B2CBF), size: 18),
          ],
        ),
      ),
    );
  }
}

// --- Екран 4: Вибір Лінійки ---
class LinesScreen extends StatelessWidget {
  final String categoryName;
  final String brandName;
  const LinesScreen({Key? key, required this.categoryName, required this.brandName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text('Каталог / $categoryName / $brandName', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brandName.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF7B2CBF), letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            const Text('Обери лінійку смаків', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('brands')
                    .doc(brandName)
                    .collection('lines')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  List<String> lineNames = docs.map((doc) => doc.id).toList();
                  if (lineNames.isEmpty) {
                    lineNames = ['For Pods', 'My Mint', 'Black', 'Lux'];
                  }

                  return ListView.builder(
                    itemCount: lineNames.length,
                    itemBuilder: (context, index) {
                      final lineName = lineNames[index];
                      return _buildLineNeonCard(
                        context,
                        lineName: lineName,
                        desc: 'Серія смаків $brandName $lineName',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineNeonCard(BuildContext context, {required String lineName, required String desc}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlavorsScreen(
              categoryName: categoryName,
              brandName: brandName,
              lineName: lineName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$brandName $lineName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7B2CBF)),
          ],
        ),
      ),
    );
  }
}

// --- Екран 5: Список Смаків ---
class FlavorsScreen extends StatelessWidget {
  final String categoryName;
  final String brandName;
  final String lineName;

  const FlavorsScreen({
    Key? key,
    required this.categoryName,
    required this.brandName,
    required this.lineName,
  }) : super(key: key);

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '240 ₴';
    String str = rawPrice.toString().replaceAll(RegExp(r'[^\d]'), '');
    return str.isEmpty ? '240 ₴' : '$str ₴';
  }

  @override
  Widget build(BuildContext context) {
    final Query flavorsQuery = FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .where('brand', isEqualTo: brandName)
        .where('line', isEqualTo: lineName);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text('$brandName / $lineName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: flavorsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Помилка: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
            }

            final List<QueryDocumentSnapshot> documents = snapshot.data?.docs ?? [];

            if (documents.isEmpty) {
              return const Center(
                child: Text(
                  'У цій лінійці наразі немає товарів',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              );
            }

            return GridView.builder(
              itemCount: documents.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;

                return _buildFlavorNeonCard(
                  context,
                  name: data['name'] ?? 'Без назви',
                  price: _formatPrice(data['price']),
                  inStock: data['inStock'] ?? false,
                  isNew: data['isNew'] ?? false,
                  imageUrl: data['imageUrl'],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlavorNeonCard(
      BuildContext context, {
        required String name,
        required String price,
        required bool inStock,
        bool isNew = false,
        String? imageUrl,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              fullName: '$brandName $lineName $name',
              price: price,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                        _getProxyImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text('💧', style: TextStyle(fontSize: 42)),
                        ),
                      )
                          : const Center(
                        child: Text('💧', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                  if (isNew)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              inStock ? '● В наявності' : '○ Немає в наявності',
              style: TextStyle(
                color: inStock ? Colors.greenAccent : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Екран 8: Картриджі (ДИНАМІЧНО З FIRESTORE БАЗИ) ---
class CartridgesScreen extends StatefulWidget {
  const CartridgesScreen({super.key});

  @override
  State<CartridgesScreen> createState() => _CartridgesScreenState();
}

class _CartridgesScreenState extends State<CartridgesScreen> {
  String _selectedModel = 'XROS';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Каталог / Картриджі', style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text('Оригінальні комплектуючі', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: ['XROS', 'OXVA', 'Voopoo'].map((model) {
                final isSelected = model == _selectedModel;
                return GestureDetector(
                  onTap: () => setState(() => _selectedModel = model),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF9D4EDD) : Colors.white.withOpacity(0.05),
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFF7B2CBF).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                          : [],
                    ),
                    child: Text(
                      model,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('category', isEqualTo: 'Картриджі')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  List<QueryDocumentSnapshot> matchedDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final compat = (data['compatibility'] ?? '').toString().toLowerCase();
                    final searchKey = _selectedModel.toLowerCase();

                    return name.contains(searchKey) || compat.contains(searchKey);
                  }).toList();

                  matchedDocs.sort((a, b) {
                    final aStock = (a.data() as Map<String, dynamic>)['inStock'] ?? false;
                    final bStock = (b.data() as Map<String, dynamic>)['inStock'] ?? false;
                    if (aStock && !bStock) return -1;
                    if (!aStock && bStock) return 1;
                    return 0;
                  });

                  if (matchedDocs.isEmpty) {
                    return Center(
                      child: Text(
                        'Картриджів $_selectedModel в базі не знайдено.\nДодайте їх через Адмінку!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: matchedDocs.length,
                    itemBuilder: (context, index) {
                      final data = matchedDocs[index].data() as Map<String, dynamic>;
                      final String name = data['name'] ?? '';
                      final String compatibility = data['compatibility'] ?? 'Оригінальні картриджі';
                      final String priceStr = '${data['price'] ?? '130'} ₴';
                      final bool inStock = data['inStock'] ?? false;
                      final bool isNew = data['isNew'] ?? false;
                      final String? imgUrl = data['imageUrl'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                fullName: name,
                                price: priceStr,
                                imageUrl: imgUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: inStock ? Colors.white.withOpacity(0.05) : Colors.redAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121212),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imgUrl != null && imgUrl.isNotEmpty
                                      ? Image.network(
                                    _getProxyImageUrl(imgUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Text('🔌', style: TextStyle(fontSize: 24)),
                                    ),
                                  )
                                      : const Center(
                                    child: Text('🔌', style: TextStyle(fontSize: 24)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: inStock ? Colors.white : Colors.grey,
                                            ),
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
                                    const SizedBox(height: 2),
                                    Text(compatibility, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                        const SizedBox(width: 10),
                                        Text(
                                          inStock ? '● В наявності' : '○ Немає в наявності',
                                          style: TextStyle(
                                            color: inStock ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Екран Подів (ДИНАМІЧНО З FIRESTORE) ---
class PodsScreen extends StatelessWidget {
  const PodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Каталог / Пристрої', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: 'Пристрої')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text('Пристроїв наразі немає в базі', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String name = data['name'] ?? '';
                final String priceStr = '${data['price'] ?? '850'} ₴';
                final bool inStock = data['inStock'] ?? false;
                final bool isNew = data['isNew'] ?? false;
                final String? imgUrl = data['imageUrl'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          fullName: name,
                          price: priceStr,
                          imageUrl: imgUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imgUrl != null && imgUrl.isNotEmpty
                                ? Image.network(_getProxyImageUrl(imgUrl), fit: BoxFit.cover)
                                : const Center(child: Text('🔋', style: TextStyle(fontSize: 26))),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                                  const SizedBox(width: 10),
                                  Text(
                                    inStock ? '● В наявності' : '○ Немає в наявності',
                                    style: TextStyle(
                                      color: inStock ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Екран Аксесуарів (ДИНАМІЧНО З FIRESTORE) ---
class AccessoriesScreen extends StatelessWidget {
  const AccessoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Каталог / Аксесуари', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: 'Аксесуари')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text('Аксесуарів наразі немає в базі', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String name = data['name'] ?? '';
                final String priceStr = '${data['price'] ?? '150'} ₴';
                final bool inStock = data['inStock'] ?? false;
                final bool isNew = data['isNew'] ?? false;
                final String? imgUrl = data['imageUrl'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          fullName: name,
                          price: priceStr,
                          imageUrl: imgUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imgUrl != null && imgUrl.isNotEmpty
                                ? Image.network(_getProxyImageUrl(imgUrl), fit: BoxFit.cover)
                                : const Center(child: Text('⚙️', style: TextStyle(fontSize: 26))),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                                  const SizedBox(width: 10),
                                  Text(
                                    inStock ? '● В наявності' : '○ Немає в наявності',
                                    style: TextStyle(
                                      color: inStock ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Екран 6: Детальна Картка Товару ---
class ProductDetailScreen extends StatefulWidget {
  final String fullName;
  final String price;
  final String? imageUrl;

  const ProductDetailScreen({
    Key? key,
    required this.fullName,
    required this.price,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  int get _unitPrice {
    final digits = widget.price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 240;
  }

  int get _totalPrice => _unitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2CBF).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? Image.network(
                    _getProxyImageUrl(widget.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('💧', style: TextStyle(fontSize: 90)),
                    ),
                  )
                      : const Center(
                    child: Text('💧', style: TextStyle(fontSize: 90)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('● В наявності', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Оригінальна продукція VAPE HOUSE. Висока якість, насичена передача смаку та надійність у використанні.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                      ),
                      Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_totalPrice ₴',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2CBF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  CartManager.addItem(
                    CartItem(
                      id: widget.fullName,
                      name: widget.fullName,
                      price: _unitPrice.toDouble(),
                      quantity: _quantity,
                      imageUrl: widget.imageUrl,
                      icon: '💧',
                    ),
                  );

                  _showModernSnackBar(
                    context,
                    'Додано в кошик: ${widget.fullName} ($_quantity шт) на суму $_totalPrice ₴',
                    icon: Icons.shopping_bag_outlined,
                  );
                },
                child: const Text('Додати в кошик', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}