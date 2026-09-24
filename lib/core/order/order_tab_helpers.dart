import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// Website `ORDER_PAGE_TABS` from `orderDisplayHelpers.ts`.
/// Short labels so all tabs stay on one horizontal line on phones.
const orderPageTabs = <(String, String)>[
  ('all', 'All'),
  ('placed', 'Placed'),
  ('preparing', 'Preparing'),
  ('delivered', 'Delivered'),
  ('cancelled', 'Cancelled'),
  ('refunded', 'Returns'),
];

class OrderStatusBadgeColors {
  const OrderStatusBadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _normalizedStatusKey(OrderModel order) {
  return order.statusKey;
}

/// Maps an order to a tab id (`orderPageTabs` first element).
String orderTabGroup(OrderModel order) {
  if (order.isReturn || order.isRefunded) return 'refunded';

  final k = _normalizedStatusKey(order);

  if (k.contains('refund')) return 'refunded';
  if (k.contains('cancel') || k.contains('fail')) return 'cancelled';
  if (k.contains('deliver') || k.contains('completed')) return 'delivered';
  if (k.contains('processing') ||
      k.contains('packed') ||
      k.contains('distribution') ||
      k.contains('facility') ||
      k.contains('out-for-delivery') ||
      k.contains('out for') ||
      k.contains('progress')) {
    return 'preparing';
  }
  if (k.contains('pending') || k.isEmpty) return 'placed';

  return 'placed';
}

Map<String, int> orderTabCounts(List<OrderModel> orders) {
  final counts = <String, int>{'all': orders.length};
  for (final tab in orderPageTabs) {
    if (tab.$1 != 'all') counts[tab.$1] = 0;
  }
  for (final o in orders) {
    final g = orderTabGroup(o);
    counts[g] = (counts[g] ?? 0) + 1;
  }
  return counts;
}

List<OrderModel> filterOrdersByTab(List<OrderModel> orders, String tab) {
  if (tab == 'all') return orders;
  return orders.where((o) => orderTabGroup(o) == tab).toList();
}

List<OrderModel> searchOrders(List<OrderModel> orders, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return orders;

  return orders.where((o) {
    if (o.displayId.toLowerCase().contains(q)) return true;
    if (o.id.toLowerCase().contains(q)) return true;
    if ((o.trackingNumber ?? '').toLowerCase().contains(q)) return true;
    for (final item in o.items) {
      if (item.name.toLowerCase().contains(q)) return true;
    }
    return false;
  }).toList();
}

OrderStatusBadgeColors badgeColorsForOrder(OrderModel order) {
  final k = _normalizedStatusKey(order);

  if (k.contains('cancel') || k.contains('fail')) {
    return OrderStatusBadgeColors(
      background: _hexColor('#fde8e8'),
      foreground: _hexColor('#e11d48'),
    );
  }
  if (k.contains('deliver') || k.contains('completed')) {
    return OrderStatusBadgeColors(
      background: _hexColor('#e8f5ed'),
      foreground: _hexColor('#1d8a4a'),
    );
  }
  if (k.contains('processing') ||
      k.contains('packed') ||
      k.contains('distribution') ||
      k.contains('facility') ||
      k.contains('out-for-delivery') ||
      k.contains('out for') ||
      k.contains('progress')) {
    return OrderStatusBadgeColors(
      background: _hexColor('#e1f0f3'),
      foreground: _hexColor('#11788c'),
    );
  }
  if (k.contains('pending') || k.isEmpty || k.contains('placed')) {
    return OrderStatusBadgeColors(
      background: _hexColor('#fff4e8'),
      foreground: _hexColor('#c27803'),
    );
  }

  return OrderStatusBadgeColors(
    background: _hexColor('#f3f4f6'),
    foreground: _hexColor('#5c6675'),
  );
}
