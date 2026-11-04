import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> icons = {
    // Expense & Living
    'shopping_cart': Icons.shopping_cart_outlined,
    'local_cafe': Icons.local_cafe_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'school': Icons.school_outlined,
    'restaurant': Icons.restaurant_outlined,
    'receipt': Icons.receipt_long_outlined,
    'home': Icons.home_outlined,
    'medical_services': Icons.medical_services_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'movie': Icons.movie_outlined,
    'more_horiz': Icons.more_horiz_outlined,
    'directions_car': Icons.directions_car_outlined,
    'two_wheeler': Icons.two_wheeler_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'local_grocery_store': Icons.local_grocery_store_outlined,
    'fastfood': Icons.fastfood_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'sports_esports': Icons.sports_esports_outlined,
    'wifi': Icons.wifi_outlined,
    'phone_android': Icons.phone_android_outlined,
    'flash_on': Icons.flash_on_outlined,
    'water_drop': Icons.water_drop_outlined,
    'apartment': Icons.apartment_outlined,
    'flight': Icons.flight_outlined,
    'train': Icons.train_outlined,
    'commute': Icons.commute_outlined,
    'book': Icons.menu_book_outlined,
    'pets': Icons.pets_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'local_pharmacy': Icons.local_pharmacy_outlined,
    'brush': Icons.brush_outlined,
    'build': Icons.build_outlined,
    'music_note': Icons.music_note_outlined,

    // Income & Finance
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'payments': Icons.payments_outlined,
    'laptop_mac': Icons.laptop_mac_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'replay': Icons.replay_outlined,
    'attach_money': Icons.currency_rupee_outlined,
    'savings': Icons.savings_outlined,
    'work': Icons.work_outline,
    'trending_up': Icons.trending_up_outlined,
    'account_balance': Icons.account_balance_outlined,
    'redeem': Icons.redeem_outlined,
    'pie_chart': Icons.pie_chart_outline,
  };

  static IconData getIcon(String? name) {
    if (name == null || !icons.containsKey(name)) {
      return Icons.category_outlined;
    }
    return icons[name]!;
  }
}

