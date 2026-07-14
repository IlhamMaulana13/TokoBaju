import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final String size;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.size,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  List<CartItem> get cartItemList {
    return _items.values.toList();
  }

  int get itemCount {
    return _items.length;
  }

  int get totalItemCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, String name, double price, String imageUrl, String size) {
    final key = '$productId-$size';
    if (_items.containsKey(key)) {
      // update quantity
      _items.update(
        key,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
        ),
      );
    } else {
      // add new item
      _items.putIfAbsent(
        key,
        () => CartItem(
          id: key,
          productId: productId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          size: size,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.remove(cartItemId);
    notifyListeners();
  }

  void incrementQuantity(String cartItemId) {
    if (_items.containsKey(cartItemId)) {
      _items.update(
        cartItemId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
        ),
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String cartItemId) {
    if (!_items.containsKey(cartItemId)) {
      return;
    }
    if (_items[cartItemId]!.quantity > 1) {
      _items.update(
        cartItemId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
          imageUrl: existingCartItem.imageUrl,
          size: existingCartItem.size,
        ),
      );
    } else {
      _items.remove(cartItemId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
