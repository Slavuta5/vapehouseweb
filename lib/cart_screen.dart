import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'cart_manager.dart';

import 'dart:js' as js;

String _getProxyImageUrl(String rawUrl) {
  if (kIsWeb && rawUrl.startsWith('http')) {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl)}';
  }
  return rawUrl;
}

void _showModernSnackBar(
    BuildContext context,
    String text, {
      IconData icon = Icons.check_circle_outline_rounded,
      Color iconColor = const Color(0xFF9D4EDD),
      Color borderColor = const Color(0xFF7B2CBF),
    }) {
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
            color: borderColor.withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.35),
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
                color: borderColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
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

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isSendingOrder = false;
  bool _isApplyingPromo = false;

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  double _discountPercentage = 0.0;
  String _appliedPromo = '';

  final String _botToken = '8360577484:AAGQzlqCbzgRyolz0_wfpVP8j7b369fgLtY';
  final String _adminChatId = '8794532038';

  @override
  void dispose() {
    _cityController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  String _getTelegramUser() {
    if (kIsWeb) {
      try {
        final tg = js.context['Telegram'];
        if (tg != null && tg['WebApp'] != null) {
          final initDataUnsafe = tg['WebApp']['initDataUnsafe'];
          if (initDataUnsafe != null && initDataUnsafe['user'] != null) {
            final user = initDataUnsafe['user'];
            final username = user['username'];
            final firstName = user['first_name'] ?? 'Покупець';
            if (username != null && username.toString().isNotEmpty) {
              return '@$username';
            } else {
              return '$firstName (без username)';
            }
          }
        }
      } catch (e) {
        debugPrint('Помилка зчитування Telegram WebApp: $e');
      }
    }
    return '@guest_user';
  }

  // Перевірка та активація промокоду через Firestore
  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (_appliedPromo == code) {
      _showModernSnackBar(
        context,
        'Промокод "$code" вже застосовано!',
        icon: Icons.info_outline,
        iconColor: Colors.amberAccent,
        borderColor: Colors.amberAccent,
      );
      return;
    }

    setState(() => _isApplyingPromo = true);

    try {
      final userTag = _getTelegramUser();
      final promoRef = FirebaseFirestore.instance.collection('promocodes').doc(code);
      final docSnap = await promoRef.get();

      if (!docSnap.exists) {
        if (mounted) {
          _showModernSnackBar(
            context,
            'Промокод "$code" не знайдено!',
            icon: Icons.error_outline_rounded,
            iconColor: Colors.redAccent,
            borderColor: Colors.redAccent,
          );
        }
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final bool isActive = data['active'] ?? true;
      final int maxActivations = data['maxActivations'] ?? 0;
      final double discount = (data['discountPercent'] ?? 10).toDouble() / 100.0;
      final List<dynamic> usedBy = data['usedBy'] ?? [];

      if (!isActive || maxActivations <= 0) {
        if (mounted) {
          _showModernSnackBar(
            context,
            'Термін дії промокоду вичерпано!',
            icon: Icons.timer_off_outlined,
            iconColor: Colors.orangeAccent,
            borderColor: Colors.orangeAccent,
          );
        }
        return;
      }

      if (usedBy.contains(userTag)) {
        if (mounted) {
          _showModernSnackBar(
            context,
            'Ви вже використовували цей промокод!',
            icon: Icons.block_outlined,
            iconColor: Colors.redAccent,
            borderColor: Colors.redAccent,
          );
        }
        return;
      }

      // Зменшуємо кількість активацій та додаємо нік користувача
      await promoRef.update({
        'maxActivations': FieldValue.increment(-1),
        'usedBy': FieldValue.arrayUnion([userTag]),
      });

      setState(() {
        _discountPercentage = discount;
        _appliedPromo = code;
      });

      if (mounted) {
        _showModernSnackBar(
          context,
          'Промокод "$code" успішно активовано! Знижка ${(discount * 100).toInt()}%',
          icon: Icons.local_offer_outlined,
          iconColor: Colors.greenAccent,
          borderColor: Colors.greenAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar(
          context,
          'Помилка перевірки промокоду',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.redAccent,
          borderColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingPromo = false);
    }
  }

  Future<void> _sendOrderToTelegramBot(String orderNum, double finalTotal) async {
    setState(() => _isSendingOrder = true);

    final userTag = _getTelegramUser();
    final List<CartItem> items = List.from(CartManager.items);
    final String city = _cityController.text.trim();

    String escapeHtml(String text) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
    }

    StringBuffer sb = StringBuffer();
    sb.writeln('🛒 <b>НОВЕ ЗАМОВЛЕННЯ №${escapeHtml(orderNum)}</b>\n');
    sb.writeln('👤 <b>Клієнт:</b> ${escapeHtml(userTag)}');
    sb.writeln('📍 <b>Місто/Село:</b> ${escapeHtml(city)}');
    if (_appliedPromo.isNotEmpty) {
      sb.writeln('🎟️ <b>Промокод:</b> ${escapeHtml(_appliedPromo)} (-${(_discountPercentage * 100).toInt()}%)');
    }
    sb.writeln('📅 <b>Дата:</b> ${DateTime.now().toString().substring(0, 16)}\n');
    sb.writeln('📦 <b>Товари:</b>');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final itemName = escapeHtml(item.name);
      final itemTotal = (item.price * item.quantity).toInt();

      sb.writeln('${i + 1}. <b>$itemName</b>');
      sb.writeln('   └ ${item.quantity} шт × ${item.price.toInt()} ₴ = <b>$itemTotal ₴</b>');
    }

    sb.writeln('\n🚚 <b>Доставка:</b> Безкоштовно');
    sb.writeln('💰 <b>Всього до сплати:</b> <b>${finalTotal.toInt()} ₴</b>');

    final String textMessage = sb.toString();

    try {
      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _adminChatId,
          'text': textMessage,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Замовлення успішно відправлено в Telegram!');
      } else {
        debugPrint('Помилка Telegram API: ${response.body}');
      }
    } catch (e) {
      debugPrint('Помилка зв\'язку з Telegram: $e');
    } finally {
      setState(() => _isSendingOrder = false);
    }
  }

  void _showSuccessDialog(String orderNum) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.greenAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Замовлення №$orderNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Дякуємо за замовлення!',
                  style: TextStyle(
                    color: Color(0xFF7B2CBF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Менеджер зв\'яжеться з вами для уточнення часу та місця доставки.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2CBF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      CartManager.clearCart();
                      _cityController.clear();
                      _promoController.clear();
                      setState(() {
                        _discountPercentage = 0.0;
                        _appliedPromo = '';
                      });
                    },
                    child: const Text(
                      'Чудово',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Кошик', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartManager.itemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => CartManager.clearCart(),
                child: const Text('Очистити', style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartManager.itemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Ваш кошик порожній', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final double subtotal = CartManager.subtotal;
          final double discount = subtotal * _discountPercentage;
          final double finalTotal = subtotal - discount;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemTotal = item.price * item.quantity;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                _getProxyImageUrl(item.imageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(item.icon.isNotEmpty ? item.icon : '💧', style: const TextStyle(fontSize: 24)),
                                ),
                              )
                                  : Center(
                                child: Text(item.icon.isNotEmpty ? item.icon : '💧', style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${itemTotal.toInt()} ₴',
                                  style: const TextStyle(color: Color(0xFF7B2CBF), fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                if (item.quantity > 1)
                                  Text(
                                    '(${item.price.toInt()} ₴ × ${item.quantity} шт)',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                                onPressed: () => CartManager.updateQuantity(item.id, -1),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF7B2CBF)),
                                onPressed: () => CartManager.updateQuantity(item.id, 1),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- МІСТО / СЕЛО ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.location_on_outlined, color: Color(0xFF7B2CBF), size: 20),
                            hintText: 'Введіть ваше Місто / Село...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- ПРОМОКОД З ОНОВЛЕНОЮ НЕОНОВОЮ КНОПКОЮ ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _appliedPromo.isNotEmpty
                                      ? Colors.greenAccent.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: TextField(
                                controller: _promoController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  icon: Icon(
                                    _appliedPromo.isNotEmpty ? Icons.check_circle_outline : Icons.confirmation_number_outlined,
                                    color: _appliedPromo.isNotEmpty ? Colors.greenAccent : Colors.grey,
                                    size: 20,
                                  ),
                                  hintText: 'Промокод (наприклад: VAPE10)',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Стильна закруглена кнопка «Застосувати»
                          SizedBox(
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B2CBF).withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                ),
                                onPressed: _isApplyingPromo ? null : _applyPromoCode,
                                child: _isApplyingPromo
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : const Text(
                                  'Застосувати',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- ПІДСУМОК ---
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Проміжна сума', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('${subtotal.toInt()} ₴', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            if (_discountPercentage > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Знижка (${(_discountPercentage * 100).toInt()}%)', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                  Text('-${discount.toInt()} ₴', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 12)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Доставка', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('Безкоштовно', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 12)),
                              ],
                            ),
                            const Divider(color: Colors.grey, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Всього', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(
                                  '${finalTotal.toInt()} ₴',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Кнопка оформлення
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B2CBF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          onPressed: _isSendingOrder
                              ? null
                              : () async {
                            if (_cityController.text.trim().isEmpty) {
                              _showModernSnackBar(
                                context,
                                'Введіть ваш населений пункт (місто/село)!',
                                icon: Icons.location_off_outlined,
                                iconColor: Colors.redAccent,
                                borderColor: Colors.redAccent,
                              );
                              return;
                            }

                            final orderNum = 'NP${(1000 + CartManager.orders.length + 1)}';

                            await _sendOrderToTelegramBot(orderNum, finalTotal);

                            CartManager.orders.add(
                              OrderItem(
                                orderNumber: orderNum,
                                date: 'Сьогодні',
                                totalAmount: finalTotal,
                                status: 'Прийнято',
                                items: List.from(CartManager.items),
                              ),
                            );

                            if (context.mounted) {
                              _showSuccessDialog(orderNum);
                            }
                          },
                          child: _isSendingOrder
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Text(
                            'Підтвердити замовлення',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 70),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}