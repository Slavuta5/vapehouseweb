import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Категорії
  String _selectedCategory = 'Рідини';
  String _filterCategory = 'Всі';

  // Для рідин
  String _selectedBrand = 'Chaser';
  String _selectedLine = 'For Pods';

  // Контролери вводу товарів
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newLineController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productStockController = TextEditingController();
  final TextEditingController _compatibilityController = TextEditingController();

  // Контролери вводу промокодів
  final TextEditingController _promoCodeController = TextEditingController();
  final TextEditingController _promoDiscountController = TextEditingController();
  final TextEditingController _promoMaxActivationsController = TextEditingController();

  String _searchQuery = '';
  XFile? _pickedImageFile;
  bool _isUploading = false;
  bool _isCreatingPromo = false;
  bool _isNewProduct = false; // Прапорець для позначки НОВИНКА

  @override
  void dispose() {
    _searchController.dispose();
    _newLineController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _compatibilityController.dispose();
    _promoCodeController.dispose();
    _promoDiscountController.dispose();
    _promoMaxActivationsController.dispose();
    super.dispose();
  }

  // Хелпер для проксі (Web)
  String _getProxyImageUrl(String rawUrl) {
    if (kIsWeb && rawUrl.startsWith('http')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl)}';
    }
    return rawUrl;
  }

  // Вибір картинки з галереї
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image != null) {
      setState(() {
        _pickedImageFile = image;
      });
    }
  }

  // --- СТВОРЕННЯ ПРОМОКОДУ ---
  Future<void> _createPromoCode() async {
    final code = _promoCodeController.text.trim().toUpperCase();
    final discountStr = _promoDiscountController.text.trim();
    final activationsStr = _promoMaxActivationsController.text.trim();

    final int discount = int.tryParse(discountStr) ?? 10;
    final int maxActivations = int.tryParse(activationsStr) ?? 5;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву промокоду!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isCreatingPromo = true);

    try {
      final promoRef = FirebaseFirestore.instance.collection('promocodes').doc(code);

      await promoRef.set({
        'code': code,
        'discountPercent': discount,
        'maxActivations': maxActivations,
        'active': true,
        'usedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _promoCodeController.clear();
      _promoDiscountController.clear();
      _promoMaxActivationsController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Промокод "$code" (-$discount%) успішно створено!'),
            backgroundColor: const Color(0xFF7B2CBF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка створення промокоду: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingPromo = false);
    }
  }

  // Видалення промокоду
  Future<void> _deletePromoCode(String promoId) async {
    await FirebaseFirestore.instance.collection('promocodes').doc(promoId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Промокод "$promoId" видалено'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Додавання нового товару
  Future<void> _addProduct() async {
    final name = _productNameController.text.trim();
    final priceStr = _productPriceController.text.trim().isEmpty ? '240' : _productPriceController.text.trim();
    final stockCount = int.tryParse(_productStockController.text.trim()) ?? 10;
    final compatibility = _compatibilityController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву товару!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      // Завантаження фото в Storage
      if (_pickedImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}.jpg';
        final ref = FirebaseStorage.instance.ref().child('product_images').child(fileName);
        final Uint8List bytes = await _pickedImageFile!.readAsBytes();

        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final Map<String, dynamic> productData = {
        'name': name,
        'category': _selectedCategory,
        'price': priceStr,
        'stockCount': stockCount,
        'inStock': stockCount > 0,
        'isNew': _isNewProduct, // Збереження прапорця НОВИНКА
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedCategory == 'Рідини') {
        productData['brand'] = _selectedBrand;
        productData['line'] = _selectedLine;

        await FirebaseFirestore.instance
            .collection('brands')
            .doc(_selectedBrand)
            .collection('lines')
            .doc(_selectedLine)
            .collection('flavors')
            .add(productData);
      } else if (_selectedCategory == 'Картриджі') {
        productData['compatibility'] = compatibility.isNotEmpty ? compatibility : 'Сумісні пристрої';
      }

      await FirebaseFirestore.instance.collection('products').add(productData);

      _productNameController.clear();
      _productPriceController.clear();
      _productStockController.clear();
      _compatibilityController.clear();
      setState(() {
        _pickedImageFile = null;
        _isNewProduct = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товар "$name" успішно додано!'),
            backgroundColor: const Color(0xFF7B2CBF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка додавання: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // Видалення товару та його зображення із Storage
  Future<void> _deleteProduct(String docId, String? imageUrl) async {
    try {
      if (imageUrl != null && imageUrl.startsWith('http')) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Не вдалося видалити фото з Storage або файл відсутній: $e');
        }
      }

      await FirebaseFirestore.instance.collection('products').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар та його фото успішно видалено!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка видалення: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Модальне вікно редагування за допомогою Олівця
  Future<void> _showEditDialog(String docId, Map<String, dynamic> data) async {
    final String category = data['category'] ?? 'Рідини';
    final editNameController = TextEditingController(text: data['name'] ?? '');
    final editPriceController = TextEditingController(text: data['price'] ?? '');
    final editCompatController = TextEditingController(text: data['compatibility'] ?? '');
    bool editIsNew = data['isNew'] ?? false;
    XFile? newPickedImage;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Редагувати: ${data['name']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Назва товару'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Ціна (₴)'),
                    ),
                    if (category == 'Картриджі') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: editCompatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Сумісність (напр. XROS 2 / 3)'),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Перемикач "НОВИНКА" у вікні редагування
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Позначити як НОВИНКА', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Відображати бейдж "Новинка" на картці', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      value: editIsNew,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setDialogState(() => editIsNew = val),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (img != null) {
                          setDialogState(() {
                            newPickedImage = img;
                          });
                        }
                      },
                      child: Container(
                        height: 70,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: newPickedImage != null ? Colors.greenAccent : const Color(0xFF7B2CBF).withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                newPickedImage != null ? Icons.check_circle : Icons.photo_camera,
                                color: newPickedImage != null ? Colors.greenAccent : const Color(0xFF7B2CBF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                newPickedImage != null ? 'Нове фото обрано!' : 'Змінити фотографію',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    setDialogState(() => isSaving = true);

                    try {
                      String? updatedImageUrl = data['imageUrl'];

                      if (newPickedImage != null) {
                        if (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http')) {
                          try {
                            await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete();
                          } catch (_) {}
                        }

                        final fileName = '${DateTime.now().millisecondsSinceEpoch}_edited.jpg';
                        final ref = FirebaseStorage.instance.ref().child('product_images').child(fileName);
                        final Uint8List bytes = await newPickedImage!.readAsBytes();
                        final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                        updatedImageUrl = await uploadTask.ref.getDownloadURL();
                      }

                      final Map<String, dynamic> updateData = {
                        'name': editNameController.text.trim(),
                        'price': editPriceController.text.trim(),
                        'isNew': editIsNew,
                        'imageUrl': updatedImageUrl,
                      };

                      if (category == 'Картриджі') {
                        updateData['compatibility'] = editCompatController.text.trim();
                      }

                      await FirebaseFirestore.instance.collection('products').doc(docId).update(updateData);

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Товар успішно оновлено!'), backgroundColor: Color(0xFF7B2CBF)),
                        );
                      }
                    } catch (e) {
                      debugPrint('Помилка при оновленні: $e');
                    } finally {
                      setDialogState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Зберегти', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Зміна кількості товару на складі
  Future<void> _updateStockCount(String docId, int newCount) async {
    final count = newCount < 0 ? 0 : newCount;
    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'stockCount': count,
      'inStock': count > 0,
    });
  }

  // Перемикання прапорця Новинки безпосередньо у списку
  Future<void> _toggleIsNew(String docId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'isNew': !currentValue,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Управління Базою Товарів', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. СТВОРЕННЯ ЛІНІЙКИ (ТІЛЬКИ ДЛЯ РІДИН) ---
            if (_selectedCategory == 'Рідини') ...[
              _buildSectionHeader('1. Створення нової лінійки рідини'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Оберіть бренд:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('Бренд'),
                      items: ['Chaser', 'Lucky', 'Hype'].map((brand) {
                        return DropdownMenuItem(value: brand, child: Text(brand));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBrand = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newLineController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Нова лінійка (Black, Lux)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2CBF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: () async {
                            final lName = _newLineController.text.trim();
                            if (lName.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('brands')
                                  .doc(_selectedBrand)
                                  .collection('lines')
                                  .doc(lName)
                                  .set({'name': lName, 'createdAt': FieldValue.serverTimestamp()});
                              _newLineController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Лінійку "$lName" додано!'), backgroundColor: const Color(0xFF7B2CBF)),
                              );
                            }
                          },
                          child: const Text('Додати', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // --- 2. СТВОРЕННЯ ТА УПРАВЛІННЯ ПРОМОКОДАМИ ---
            _buildSectionHeader('2. Створення та управління промокодами'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _promoCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Промокод (наприклад: VAPE10)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoDiscountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Знижка (%) (напр.: 10)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _promoMaxActivationsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Активацій (напр.: 5)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2CBF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isCreatingPromo ? null : _createPromoCode,
                      child: _isCreatingPromo
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Створити промокод', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),

                  const Text('Активні промокоди:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('promocodes').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Немає створених промокодів', style: TextStyle(color: Colors.grey, fontSize: 12));
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final promoId = docs[index].id;
                          final int discount = data['discountPercent'] ?? 10;
                          final int maxActivations = data['maxActivations'] ?? 0;
                          final List<dynamic> usedBy = data['usedBy'] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      promoId,
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Знижка: -$discount% • Залишилось: $maxActivations • Використано: ${usedBy.length}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deletePromoCode(promoId),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. ФОРМА ДОДАВАННЯ ТОВАРІВ ---
            _buildSectionHeader('3. Додати новий товар в асортимент'),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Оберіть категорію товару:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Рідини', 'Картриджі', 'Пристрої', 'Аксесуари'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF9D4EDD) : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Text(
                              cat,
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
                  ),

                  const SizedBox(height: 14),

                  if (_selectedCategory == 'Рідини') ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('brands')
                          .doc(_selectedBrand)
                          .collection('lines')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        List<String> lines = docs.map((d) => d.id).toList();
                        if (lines.isEmpty) lines = ['For Pods'];
                        if (!lines.contains(_selectedLine)) _selectedLine = lines.first;

                        return DropdownButtonFormField<String>(
                          value: _selectedLine,
                          dropdownColor: const Color(0xFF1E1E1E),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: _inputDecoration('Лінійка'),
                          items: lines.map((line) => DropdownMenuItem(value: line, child: Text(line))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLine = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_selectedCategory == 'Картриджі') ...[
                    TextField(
                      controller: _compatibilityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Сумісність (напр.: XROS 2 / 3 / Nano)'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _productNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      _selectedCategory == 'Рідини'
                          ? 'Назва смаку (наприклад: 🍓 Полуниця)'
                          : 'Назва (наприклад: XROS 0.6Ω 3мл або Vaporesso XROS 3)',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _productPriceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Ціна (₴)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _productStockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Кількість (шт)'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ПРАПОРЕЦЬ НОВИНКА ПРИ СТВОРЕННІ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 6),
                          Text('Позначити як НОВИНКА', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      value: _isNewProduct,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _isNewProduct = val),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _pickedImageFile != null ? Colors.greenAccent : const Color(0xFF7B2CBF).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: _pickedImageFile != null
                          ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Обрано: ${_pickedImageFile!.name}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: Color(0xFF7B2CBF), size: 26),
                          SizedBox(height: 4),
                          Text('Обрати фото з галереї', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2CBF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isUploading ? null : _addProduct,
                      child: _isUploading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Зберегти в "$_selectedCategory"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 4. НАЯВНІСТЬ ТА РЕДАГУВАННЯ СКЛАДУ ---
            _buildSectionHeader('4. Наявність та редагування складу'),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Всі', 'Рідини', 'Картриджі', 'Пристрої', 'Аксесуари'].map((cat) {
                  final isSel = _filterCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _filterCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF7B2CBF).withOpacity(0.3) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF7B2CBF) : Colors.transparent),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Пошук за назвою або брендом...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7B2CBF)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 14),

            // СПИСОК ТОВАРІВ З FIRESTORE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Помилка: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2CBF)));
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final brand = (data['brand'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? 'Рідини';

                  final matchesSearch = name.contains(_searchQuery) || brand.contains(_searchQuery);
                  final matchesCat = _filterCategory == 'Всі' || category == _filterCategory;

                  return matchesSearch && matchesCat;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Товарів не знайдено', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final bool inStock = data['inStock'] ?? false;
                    final bool isNew = data['isNew'] ?? false;
                    final int stockCount = data['stockCount'] ?? 0;
                    final String? imgUrl = data['imageUrl'];
                    final String category = data['category'] ?? 'Рідини';

                    String subtitleStr = '${data['price'] ?? '240'} ₴';
                    if (category == 'Рідини') {
                      subtitleStr = '${data['brand'] ?? ''} ${data['line'] ?? ''} • $subtitleStr';
                    } else if (category == 'Картриджі') {
                      subtitleStr = '${data['compatibility'] ?? ''} • $subtitleStr';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: inStock ? const Color(0xFF7B2CBF).withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121212),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: (imgUrl != null && imgUrl.isNotEmpty)
                                      ? Image.network(
                                    _getProxyImageUrl(imgUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.broken_image_outlined, color: Colors.orangeAccent, size: 20),
                                      );
                                    },
                                  )
                                      : const Center(
                                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7B2CBF).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            category,
                                            style: const TextStyle(color: Color(0xFF7B2CBF), fontSize: 9, fontWeight: FontWeight.bold),
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
                                              '🔥 NEW',
                                              style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      subtitleStr,
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // КНОПКА ПЕРЕМЕКАННЯ ПРАПОРЦЯ НОВИНКА (NEW)
                              IconButton(
                                tooltip: 'Позначити як НОВИНКА',
                                icon: Icon(
                                  Icons.local_fire_department,
                                  color: isNew ? Colors.cyanAccent : Colors.grey.withOpacity(0.3),
                                  size: 22,
                                ),
                                onPressed: () => _toggleIsNew(docId, isNew),
                              ),

                              Switch(
                                value: inStock,
                                activeColor: Colors.greenAccent,
                                onChanged: (val) {
                                  FirebaseFirestore.instance.collection('products').doc(docId).update({
                                    'inStock': val,
                                    if (!val) 'stockCount': 0,
                                  });
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF7B2CBF), size: 22),
                                onPressed: () {
                                  _showEditDialog(docId, data);
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                onPressed: () {
                                  _deleteProduct(docId, imgUrl);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Кількість на складі:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Row(
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                                      onPressed: () => _updateStockCount(docId, stockCount - 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        '$stockCount шт',
                                        style: TextStyle(
                                          color: stockCount > 0 ? Colors.greenAccent : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7B2CBF), size: 20),
                                      onPressed: () => _updateStockCount(docId, stockCount + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF121212),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B2CBF)),
      ),
    );
  }
}