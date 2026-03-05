import 'menu_item.dart';

/// Represents a menu item in the cart with quantity
class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  /// Total price for this cart item
  double get totalPrice => menuItem.price * quantity;

  /// Formatted total price
  String get formattedTotal => '₹${totalPrice.toInt()}';
}

/// Shopping cart for managing order items
class Cart {
  final Map<String, CartItem> _items = {};

  /// Get all cart items as a list
  List<CartItem> get items => _items.values.toList();

  /// Total number of items in cart
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Grand total of all items
  double get grandTotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Formatted grand total
  String get formattedTotal => '₹${grandTotal.toInt()}';

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => _items.isNotEmpty;

  /// Generate order description from cart items
  String get orderDescription {
    if (_items.isEmpty) return '';
    
    final itemNames = items.map((item) => item.menuItem.name).toList();
    if (itemNames.length <= 3) {
      return itemNames.join(', ');
    }
    
    final firstThree = itemNames.take(3).join(', ');
    final remaining = itemNames.length - 3;
    return '$firstThree +$remaining more';
  }

  /// Add item to cart (increment if exists, create if new)
  void add(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
  }

  /// Remove one quantity of item (delete if reaches 0)
  void remove(MenuItem menuItem) {
    if (!_items.containsKey(menuItem.id)) return;
    
    if (_items[menuItem.id]!.quantity > 1) {
      _items[menuItem.id]!.quantity--;
    } else {
      _items.remove(menuItem.id);
    }
  }

  /// Remove item entirely from cart
  void removeAll(String itemId) {
    _items.remove(itemId);
  }

  /// Clear all items from cart
  void clear() {
    _items.clear();
  }

  /// Check if item is in cart
  bool contains(String itemId) {
    return _items.containsKey(itemId);
  }

  /// Get quantity of specific item
  int quantityOf(String itemId) {
    return _items[itemId]?.quantity ?? 0;
  }

  /// Convert cart to line items for order
  List<Map<String, dynamic>> toLineItems() {
    return items.map((cartItem) {
      return {
        'id': cartItem.menuItem.id,
        'name': cartItem.menuItem.name,
        'price': cartItem.menuItem.price,
        'quantity': cartItem.quantity,
        'total': cartItem.totalPrice,
      };
    }).toList();
  }
}
