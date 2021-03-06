import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/cart.dart';
import 'package:shop/util/constants.dart';

class Order {
  final String id;
  final double total;
  final List<CartItem> products;
  final DateTime date;

  Order({
    @required this.id,
    @required this.total,
    @required this.products,
    @required this.date,
  });
}

class Orders with ChangeNotifier {
  final String _baseUrl = '${Constants.BASE_API_URL}orders';
  final String _token;
  final String _userId;
  List<Order> _items = [];

  Orders([
    this._token,
    this._userId,
    this._items = const [],
  ]);

  List<Order> get items {
    return [..._items];
  }

  int get itemsCount {
    return this._items.length;
  }

  Future<void> loadOrders() async {
    List<Order> loadedItems = [];

    final response = await http.get("$_baseUrl/$_userId.json?auth=$_token");
    Map<String, dynamic> data = json.decode(response.body);

    loadedItems.clear();

    if (data != null) {
      data.forEach((orderId, orderData) {
        loadedItems.add(
          new Order(
            id: orderId,
            total: orderData['total'],
            products: (orderData['products'] as List<dynamic>).map((item) {
              return CartItem(
                id: item['id'],
                productId: item['productId'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price'],
              );
            }).toList(),
            date: DateTime.parse(orderData['date']),
          ),
        );
      });
      notifyListeners();
    }

    _items = loadedItems.reversed.toList();
    return Future.value();
  }

  Future<void> addOrder(Cart cart) async {
    // final anotherTotal = cart.items.values.toList().fold(
    //       0.0,
    //       (previousValue, element) =>
    //           previousValue + (element.price * element.quantity),
    //     );

    final date = DateTime.now();

    final response = await http.post(
      "$_baseUrl/$_userId.json?auth=$_token",
      body: jsonEncode({
        'total': cart.totalAmount,
        'date': date.toIso8601String(),
        'products': cart.items.values
            .map((cartItem) => {
                  'id': cartItem.id,
                  'productId': cartItem.productId,
                  'title': cartItem.title,
                  'quantity': cartItem.quantity,
                  'price': cartItem.price,
                })
            .toList()
      }),
    );

    this._items.insert(
          0,
          new Order(
            id: json.decode(response.body)['name'],
            total: cart.totalAmount,
            products: cart.items.values.toList(),
            date: DateTime.now(),
          ),
        );

    notifyListeners();
  }
}
