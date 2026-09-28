import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String icon;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.icon = '💧',
    this.imageUrl,
    this.quantity = 1,
  });
}

class OrderItem {
  final String orderNumber;
  final String date;
  final double totalAmount;
  final String status;
  final List<CartItem> items;

  OrderItem({
    required this.orderNumber,
    required this.date,
    required this.totalAmount,
    required this.status,
    required this.items,
  });
}

class CartManager {
  static final ValueNotifier<List<CartItem>> itemsNotifier = ValueNotifier<List<CartItem>>([]);
  static final List<OrderItem> orders = [];

  // Доставка безкоштовна
  static double shippingCost = 0.0;

  static List<CartItem> get items => itemsNotifier.value;

  static double get subtotal {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  static double get total {
    if (items.isEmpty) return 0.0;
    return subtotal + shippingCost;
  }

  static void addItem(CartItem item) {
    final currentList = List<CartItem>.from(itemsNotifier.value);
    final index = currentList.indexWhere((element) => element.id == item.id);

    if (index != -1) {
      currentList[index].quantity += item.quantity;
    } else {
      currentList.add(item);
    }

    itemsNotifier.value = currentList;
  }

  static void removeItem(String id) {
    final currentList = List<CartItem>.from(itemsNotifier.value);
    currentList.removeWhere((element) => element.id == id);
    itemsNotifier.value = currentList;
  }

  static void updateQuantity(String id, int delta) {
    final currentList = List<CartItem>.from(itemsNotifier.value);
    final index = currentList.indexWhere((element) => element.id == id);
    if (index != -1) {
      currentList[index].quantity += delta;
      if (currentList[index].quantity <= 0) {
        currentList.removeAt(index);
      }
      itemsNotifier.value = currentList;
    }
  }

  static void clearCart() {
    itemsNotifier.value = [];
  }
}