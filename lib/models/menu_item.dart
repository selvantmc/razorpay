/// Model representing a menu item in the restaurant
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageAsset;
  final bool isVeg;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageAsset,
    required this.isVeg,
    this.isAvailable = true,
  });

  /// Format price as rupees
  String get formattedPrice => '₹${price.toInt()}';
}

/// Static menu data with categories and items
class MenuData {
  static const List<String> categories = [
    'All',
    'Starters',
    'Main Course',
    'Breads',
    'Rice & Biryani',
    'Drinks',
    'Desserts',
  ];

  static const List<MenuItem> items = [
    // Starters
    MenuItem(
      id: 's1',
      name: 'Paneer Tikka',
      description: 'Grilled cottage cheese marinated in spices',
      price: 180,
      category: 'Starters',
      imageAsset: '🧀',
      isVeg: true,
    ),
    MenuItem(
      id: 's2',
      name: 'Chicken 65',
      description: 'Spicy deep-fried chicken with curry leaves',
      price: 220,
      category: 'Starters',
      imageAsset: '🍗',
      isVeg: false,
    ),
    MenuItem(
      id: 's3',
      name: 'Veg Spring Rolls',
      description: 'Crispy rolls filled with vegetables',
      price: 140,
      category: 'Starters',
      imageAsset: '🥟',
      isVeg: true,
    ),
    MenuItem(
      id: 's4',
      name: 'Fish Fingers',
      description: 'Crispy fried fish strips with tartar sauce',
      price: 240,
      category: 'Starters',
      imageAsset: '🐟',
      isVeg: false,
    ),
    MenuItem(
      id: 's5',
      name: 'Mushroom Pepper Fry',
      description: 'Sautéed mushrooms with black pepper',
      price: 160,
      category: 'Starters',
      imageAsset: '🍄',
      isVeg: true,
    ),

    // Main Course
    MenuItem(
      id: 'm1',
      name: 'Butter Chicken',
      description: 'Creamy tomato-based chicken curry',
      price: 280,
      category: 'Main Course',
      imageAsset: '🍛',
      isVeg: false,
    ),
    MenuItem(
      id: 'm2',
      name: 'Paneer Butter Masala',
      description: 'Cottage cheese in rich tomato gravy',
      price: 240,
      category: 'Main Course',
      imageAsset: '🍲',
      isVeg: true,
    ),
    MenuItem(
      id: 'm3',
      name: 'Dal Makhani',
      description: 'Black lentils cooked with butter and cream',
      price: 180,
      category: 'Main Course',
      imageAsset: '🥘',
      isVeg: true,
    ),
    MenuItem(
      id: 'm4',
      name: 'Mutton Rogan Josh',
      description: 'Aromatic lamb curry with Kashmiri spices',
      price: 340,
      category: 'Main Course',
      imageAsset: '🍖',
      isVeg: false,
    ),
    MenuItem(
      id: 'm5',
      name: 'Palak Paneer',
      description: 'Cottage cheese in spinach gravy',
      price: 220,
      category: 'Main Course',
      imageAsset: '🥬',
      isVeg: true,
    ),
    MenuItem(
      id: 'm6',
      name: 'Chicken Tikka Masala',
      description: 'Grilled chicken in spiced tomato sauce',
      price: 300,
      category: 'Main Course',
      imageAsset: '🍗',
      isVeg: false,
    ),

    // Breads
    MenuItem(
      id: 'b1',
      name: 'Butter Naan',
      description: 'Soft leavened bread with butter',
      price: 50,
      category: 'Breads',
      imageAsset: '🫓',
      isVeg: true,
    ),
    MenuItem(
      id: 'b2',
      name: 'Garlic Naan',
      description: 'Naan topped with garlic and coriander',
      price: 60,
      category: 'Breads',
      imageAsset: '🧄',
      isVeg: true,
    ),
    MenuItem(
      id: 'b3',
      name: 'Tandoori Roti',
      description: 'Whole wheat flatbread from tandoor',
      price: 40,
      category: 'Breads',
      imageAsset: '🥖',
      isVeg: true,
    ),
    MenuItem(
      id: 'b4',
      name: 'Cheese Naan',
      description: 'Naan stuffed with melted cheese',
      price: 80,
      category: 'Breads',
      imageAsset: '🧀',
      isVeg: true,
    ),

    // Rice & Biryani
    MenuItem(
      id: 'r1',
      name: 'Chicken Biryani',
      description: 'Fragrant basmati rice with spiced chicken',
      price: 280,
      category: 'Rice & Biryani',
      imageAsset: '🍚',
      isVeg: false,
    ),
    MenuItem(
      id: 'r2',
      name: 'Veg Biryani',
      description: 'Mixed vegetables with aromatic rice',
      price: 220,
      category: 'Rice & Biryani',
      imageAsset: '🥗',
      isVeg: true,
    ),
    MenuItem(
      id: 'r3',
      name: 'Mutton Biryani',
      description: 'Tender lamb pieces with saffron rice',
      price: 360,
      category: 'Rice & Biryani',
      imageAsset: '🍖',
      isVeg: false,
    ),
    MenuItem(
      id: 'r4',
      name: 'Jeera Rice',
      description: 'Basmati rice tempered with cumin',
      price: 120,
      category: 'Rice & Biryani',
      imageAsset: '🍚',
      isVeg: true,
    ),

    // Drinks
    MenuItem(
      id: 'd1',
      name: 'Mango Lassi',
      description: 'Sweet yogurt drink with mango pulp',
      price: 80,
      category: 'Drinks',
      imageAsset: '🥭',
      isVeg: true,
    ),
    MenuItem(
      id: 'd2',
      name: 'Masala Chai',
      description: 'Spiced Indian tea with milk',
      price: 40,
      category: 'Drinks',
      imageAsset: '☕',
      isVeg: true,
    ),
    MenuItem(
      id: 'd3',
      name: 'Fresh Lime Soda',
      description: 'Refreshing lime juice with soda',
      price: 60,
      category: 'Drinks',
      imageAsset: '🍋',
      isVeg: true,
    ),
    MenuItem(
      id: 'd4',
      name: 'Cold Coffee',
      description: 'Chilled coffee with ice cream',
      price: 100,
      category: 'Drinks',
      imageAsset: '🧊',
      isVeg: true,
    ),

    // Desserts
    MenuItem(
      id: 'de1',
      name: 'Gulab Jamun',
      description: 'Soft milk dumplings in sugar syrup',
      price: 80,
      category: 'Desserts',
      imageAsset: '🍡',
      isVeg: true,
    ),
    MenuItem(
      id: 'de2',
      name: 'Rasmalai',
      description: 'Cottage cheese patties in sweet milk',
      price: 100,
      category: 'Desserts',
      imageAsset: '🥛',
      isVeg: true,
    ),
    MenuItem(
      id: 'de3',
      name: 'Kulfi',
      description: 'Traditional Indian ice cream',
      price: 70,
      category: 'Desserts',
      imageAsset: '🍦',
      isVeg: true,
    ),
    MenuItem(
      id: 'de4',
      name: 'Gajar Halwa',
      description: 'Carrot pudding with nuts and ghee',
      price: 90,
      category: 'Desserts',
      imageAsset: '🥕',
      isVeg: true,
    ),
  ];

  /// Get items by category
  static List<MenuItem> byCategory(String category) {
    if (category == 'All') {
      return items;
    }
    return items.where((item) => item.category == category).toList();
  }
}
