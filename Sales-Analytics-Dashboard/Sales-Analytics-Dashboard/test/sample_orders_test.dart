import 'package:flutter_test/flutter_test.dart';
import 'package:sales_analytics_dashboard/models/mock_orders.dart';
import 'package:sales_analytics_dashboard/models/orderModel.dart';
import 'package:sales_analytics_dashboard/services/analytics_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled synthetic dataset can be parsed and analysed', () async {
    final now = DateTime(2026, 10, 23, 12);
    final orders = await loadMockOrders(now: now);
    expect(orders.length, greaterThan(300));
    expect(orders.any((o) => o.status == OrderStatus.cancelled), isTrue);
    expect(orders.every((o) => o.items.isNotEmpty), isTrue);
    expect(orders.every((o) => o.totalPriceCents > 0), isTrue);
    expect(orders.map((o) => o.id).toSet().length, orders.length);

    final result = calculateAnalytics(orders, AnalyticsRange.thirtyDays, now: now);
    expect(result.totalOrders, greaterThan(0));
    expect(result.totalRevenueCents, greaterThan(0));
    expect(result.topItems, isNotEmpty);
    expect(result.trend.fold<int>(0, (total, point) =>
        total + point.orderCount), result.totalOrders);
    expect(result.trend.fold<int>(0, (total, point) =>
        total + point.revenueCents), result.totalRevenueCents);
  });
}
