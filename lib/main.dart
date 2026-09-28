import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'cart_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Гнучка ініціалізація: для Web (Chrome) використовуємо FirebaseOptions,
  // для Android налаштування беруться з google-services.json
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDS-OiUmdt3iWANvJtVFdZT49GX-TgA6Ro",
        authDomain: "vape-house-6a3ed.firebaseapp.com",
        projectId: "vape-house-6a3ed",
        storageBucket: "vape-house-6a3ed.firebasestorage.app",
        messagingSenderId: "465777878499",
        appId: "1:465777878499:web:142b1fac4da6e7b0sb2cd6",
        measurementId: "G-B4P6CBTSV7",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const VapeHouseApp());
}

class VapeHouseApp extends StatelessWidget {
  const VapeHouseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAPE HOUSE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF7B2CBF),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'out_icon': Icons.home_outlined, 'label': 'Головна'},
    {'icon': Icons.grid_view_rounded, 'out_icon': Icons.grid_view, 'label': 'Каталог'},
    {'icon': Icons.shopping_cart_rounded, 'out_icon': Icons.shopping_cart_outlined, 'label': 'Кошик'},
    {'icon': Icons.person_rounded, 'out_icon': Icons.person_outline, 'label': 'Профіль'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Контент заходить під напівпрозору панель
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCustomBottomBar(),
          ),
        ],
      ),
    );
  }

  // --- ВІДЖЕТ: КАСТOМНА НАВІГАЦІЙНА ПАНЕЛЬ З БЛЮРОМ ТА М'ЯКИМ СЯЙВОМ ---
  Widget _buildCustomBottomBar() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF7B2CBF).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2CBF).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tabWidth = constraints.maxWidth / _navItems.length;

                return Stack(
                  children: [
                    // --- М'ЯКЕ ТОЧКОВЕ СЯЙВО ПІД АКТИВНОЮ КНОПКОЮ ---
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: (_currentIndex * tabWidth) + (tabWidth / 2) - 60,
                      bottom: -20,
                      child: IgnorePointer(
                        child: Container(
                          width: 120,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.bottomCenter,
                              radius: 0.8,
                              colors: [
                                const Color(0xFF9D4EDD).withOpacity(0.35),
                                const Color(0xFF7B2CBF).withOpacity(0.12),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- ЕЛЕМЕНТИ НАВІГАЦІЇ ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_navItems.length, (index) {
                        final bool isSelected = _currentIndex == index;
                        final item = _navItems[index];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          child: Container(
                            width: tabWidth,
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7B2CBF).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAnimatedIcon(index, isSelected),
                                  const SizedBox(height: 3),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFD8B4FE)
                                          : Colors.grey[400],
                                      fontSize: isSelected ? 10.5 : 9.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      height: 1.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    child: Text(item['label']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- ІКОНКА З АНІМАЦІЄЮ ТА ЛІЧИЛЬНИКОМ КІЛЬКОСТІ В КОШИКУ ---
  Widget _buildAnimatedIcon(int index, bool isSelected) {
    final item = _navItems[index];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: isSelected ? 1.1 : 1.0,
          child: Icon(
            isSelected ? item['icon'] : item['out_icon'],
            color: isSelected ? const Color(0xFFD8B4FE) : Colors.grey[400],
            size: 22,
          ),
        ),
        if (index == 2 && CartManager.items.isNotEmpty)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF7B2CBF),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '${CartManager.items.length}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}