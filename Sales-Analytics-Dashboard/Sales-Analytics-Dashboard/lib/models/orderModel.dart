/// Each order item's line amount is quantity x unit price, in cents.
/// Using integer cents avoids floating-point errors in sales calculations.
class OrderItem {
  final String sku;
  final String name;
  final String category;
  final int unitPriceCents;
  final int quantity;

  const OrderItem({
    required this.sku,
    required this.name,
    required this.category,
    required this.unitPriceCents,
    required this.quantity,
  }) : assert(unitPriceCents >= 0),
       assert(quantity > 0);

  int get lineTotalCents => unitPriceCents * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      sku: json['sku'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unitPriceCents: (json['unitPriceCents'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

enum OrderStatus { completed, cancelled }

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime orderTime;
  final OrderStatus status;
  final List<OrderItem> items;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.orderTime,
    required this.status,
    required this.items,
  });

  bool get isCompleted => status == OrderStatus.completed;

  int get totalPriceCents =>
      items.fold<int>(0, (sum, item) => sum + item.lineTotalCents);

  double get totalPrice => totalPriceCents / 100.0;

  /// Demo JSON can use `daysAgo` so recent orders stay recent when the app
  /// runs months later. A real API can instead send ISO 8601 `orderTime`.
  factory OrderModel.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final DateTime orderDate;
    if (json['orderTime'] != null) {
      orderDate = DateTime.parse(json['orderTime'] as String).toLocal();
    } else {
      final daysAgo = (json['daysAgo'] as num).toInt();
      final hour = ((json['hour'] ?? 12) as num).toInt();
      final minute = ((json['minute'] ?? 0) as num).toInt();
      orderDate = DateTime(
        anchor.year, anchor.month, anchor.day - daysAgo, hour, minute,
      );
    }

    final statusValue = json['status'] as String? ?? 'completed';
    if (statusValue != 'completed' && statusValue != 'cancelled') {
      throw FormatException('Unknown order status: $statusValue');
    }

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      orderTime: orderDate,
      status: statusValue == 'completed'
          ? OrderStatus.completed
          : OrderStatus.cancelled,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
