import 'package:flutter_test/flutter_test.dart';
import 'package:sales_analytics_dashboard/models/orderModel.dart';
import 'package:sales_analytics_dashboard/services/analytics_calculator.dart';

OrderModel order({required String id, required String customerId,
    required DateTime time, required int unitCents, int quantity = 1,
    OrderStatus status = OrderStatus.completed}) => OrderModel(
  id: id, customerId: customerId, customerName: customerId,
  orderTime: time, status: status,
  items: [OrderItem(
    sku: 'SKU1', name: 'Test Item', category: 'Office',
    unitPriceCents: unitCents, quantity: quantity,
  )],
);

void main() {
  final now = DateTime(2026, 10, 23, 12);

  test('item totals come from unit price times quantity in cents', () {
    final model = order(id: '1', customerId: 'a',
        time: now, unitCents: 2990, quantity: 3);
    expect(model.totalPriceCents, 8970);
    expect(model.totalPrice, 89.70);
  });

  test('cancelled orders are excluded and customers are unique', () {
    final orders = [
      order(id: '1', customerId: 'A', time: now, unitCents: 2500, quantity: 2),
      order(id: '2', customerId: 'A', time: now, unitCents: 1000),
      order(id: '3', customerId: 'B', time: now, unitCents: 3000),
      order(id: '4', customerId: 'C', time: now, unitCents: 90000,
          status: OrderStatus.cancelled),
    ];
    final result = calculateAnalytics(orders, AnalyticsRange.sevenDays, now: now);
    expect(result.totalOrders, 3);
    expect(result.totalRevenueCents, 9000);
    expect(result.uniqueCustomers, 2);
    expect(result.averageOrderCents, 3000);
    expect(result.categoryQuantities['Office'], 4);
    expect(result.topItems.first.quantity, 4);
    expect(result.topItems.first.revenueCents, 9000);
    expect(result.trend.fold<int>(0, (n, p) => n + p.revenueCents), 9000);
  });

  test('period change compares equal-length adjacent windows', () {
    final orders = [
      order(id: 'old', customerId: 'A',
          time: DateTime(2026, 10, 14), unitCents: 2000),
      order(id: 'new1', customerId: 'A',
          time: DateTime(2026, 10, 23), unitCents: 2000),
      order(id: 'new2', customerId: 'B',
          time: DateTime(2026, 10, 22), unitCents: 2000),
    ];
    final result = calculateAnalytics(orders, AnalyticsRange.sevenDays, now: now);
    expect(result.revenueChange, closeTo(100, 0.0001));
    expect(result.ordersChange, closeTo(100, 0.0001));
    expect(result.customersChange, closeTo(100, 0.0001));
    expect(result.averageChange, closeTo(0, 0.0001));
  });

  test('empty comparison baseline is shown as N/A instead of 0% change', () {
    final result = calculateAnalytics([
      order(id: '1', customerId: 'A', time: now, unitCents: 100),
    ], AnalyticsRange.sevenDays, now: now);
    expect(result.ordersChange, isNull);
    expect(result.revenueChange, isNull);
  });

  test('monthly buckets keep years separate', () {
    final orders = [
      order(id: '1', customerId: 'A',
          time: DateTime(2025, 12, 20), unitCents: 500),
      order(id: '2', customerId: 'B',
          time: DateTime(2026, 1, 4), unitCents: 1000),
    ];
    final result = calculateAnalytics(orders, AnalyticsRange.oneYear, now: now);
    expect(result.trend.where((p) => p.label == '12/25').single.revenueCents, 500);
    expect(result.trend.where((p) => p.label == '1/26').single.revenueCents, 1000);
  });
}
