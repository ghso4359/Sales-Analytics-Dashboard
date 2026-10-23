import 'dart:math' as math;
import 'package:sales_analytics_dashboard/models/orderModel.dart';

enum AnalyticsRange { sevenDays, thirtyDays, ninetyDays, oneYear, allTime }

extension AnalyticsRangeLabel on AnalyticsRange {
  int? get days => switch (this) {
    AnalyticsRange.sevenDays => 7,
    AnalyticsRange.thirtyDays => 30,
    AnalyticsRange.ninetyDays => 90,
    AnalyticsRange.oneYear => 365,
    AnalyticsRange.allTime => null,
  };

  String get label => switch (this) {
    AnalyticsRange.sevenDays => 'Last 7 days',
    AnalyticsRange.thirtyDays => 'Last 30 days',
    AnalyticsRange.ninetyDays => 'Last 90 days',
    AnalyticsRange.oneYear => 'Last 365 days',
    AnalyticsRange.allTime => 'All time',
  };

  String get comparisonLabel =>
      days == null ? 'No comparison' : 'vs previous $days days';
}

class TrendPoint {
  final String label;
  final int orderCount;
  final int revenueCents;

  const TrendPoint(this.label, this.orderCount, this.revenueCents);
}

class ProductPerformance {
  final String sku;
  final String name;
  final int quantity;
  final int revenueCents;

  const ProductPerformance({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.revenueCents,
  });
}

class AnalyticsSnapshot {
  final int totalOrders;
  final int totalRevenueCents;
  final int uniqueCustomers;
  final double averageOrderCents;
  final double? revenueChange;
  final double? ordersChange;
  final double? customersChange;
  final double? averageChange;
  final List<TrendPoint> trend;
  final Map<String, int> categoryQuantities;
  final List<ProductPerformance> topItems;
  final List<OrderModel> recentOrders;

  const AnalyticsSnapshot({
    required this.totalOrders,
    required this.totalRevenueCents,
    required this.uniqueCustomers,
    required this.averageOrderCents,
    required this.revenueChange,
    required this.ordersChange,
    required this.customersChange,
    required this.averageChange,
    required this.trend,
    required this.categoryQuantities,
    required this.topItems,
    required this.recentOrders,
  });
}

class _Summary {
  final int count;
  final int revenue;
  final int customers;
  const _Summary(this.count, this.revenue, this.customers);
  double get average => count == 0 ? 0 : revenue / count;
}

_Summary _summarise(List<OrderModel> orders) => _Summary(
  orders.length,
  orders.fold<int>(0, (sum, order) => sum + order.totalPriceCents),
  orders.map((order) => order.customerId).toSet().length,
);

double? _percentChange(num current, num previous) =>
    previous == 0 ? null : (current - previous) / previous * 100;

int _calendarDaysBetween(DateTime later, DateTime earlier) =>
    DateTime.utc(later.year, later.month, later.day)
        .difference(DateTime.utc(earlier.year, earlier.month, earlier.day))
        .inDays;

AnalyticsSnapshot calculateAnalytics(
  List<OrderModel> allOrders,
  AnalyticsRange range, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final endExclusive = DateTime(
    reference.year, reference.month, reference.day + 1,
  );
  final days = range.days;
  final DateTime? start = days == null
      ? null
      : DateTime(reference.year, reference.month, reference.day - days + 1);
  final DateTime? previousStart = days == null || start == null
      ? null
      : DateTime(start.year, start.month, start.day - days);

  // Cancelled orders and future-dated records NEVER count as sales.
  final selected = allOrders.where((order) =>
      order.isCompleted &&
      !order.orderTime.isAfter(reference) &&
      order.orderTime.isBefore(endExclusive) &&
      (start == null || !order.orderTime.isBefore(start))).toList();

  final previous = allOrders.where((order) =>
      order.isCompleted && previousStart != null && start != null &&
      !order.orderTime.isBefore(previousStart) &&
      order.orderTime.isBefore(start)).toList();

  final summary = _summarise(selected);
  final prior = _summarise(previous);
  final categoryQuantities = <String, int>{};
  final quantities = <String, int>{};
  final revenues = <String, int>{};
  final names = <String, String>{};

  for (final order in selected) {
    for (final item in order.items) {
      categoryQuantities.update(
        item.category, (n) => n + item.quantity,
        ifAbsent: () => item.quantity,
      );
      quantities.update(
        item.sku, (n) => n + item.quantity,
        ifAbsent: () => item.quantity,
      );
      revenues.update(
        item.sku, (n) => n + item.lineTotalCents,
        ifAbsent: () => item.lineTotalCents,
      );
      names[item.sku] = item.name;
    }
  }

  final topItems = quantities.entries.map((item) => ProductPerformance(
    sku: item.key,
    name: names[item.key]!,
    quantity: item.value,
    revenueCents: revenues[item.key]!,
  )).toList()
    ..sort((a, b) {
      final byQuantity = b.quantity.compareTo(a.quantity);
      return byQuantity != 0
          ? byQuantity : b.revenueCents.compareTo(a.revenueCents);
    });

  selected.sort((a, b) => b.orderTime.compareTo(a.orderTime));

  return AnalyticsSnapshot(
    totalOrders: summary.count,
    totalRevenueCents: summary.revenue,
    uniqueCustomers: summary.customers,
    averageOrderCents: summary.average,
    revenueChange: days == null ? null
        : _percentChange(summary.revenue, prior.revenue),
    ordersChange: days == null ? null
        : _percentChange(summary.count, prior.count),
    customersChange: days == null ? null
        : _percentChange(summary.customers, prior.customers),
    averageChange: days == null ? null
        : _percentChange(summary.average, prior.average),
    trend: _createTrend(selected, range, reference, start),
    categoryQuantities: categoryQuantities,
    topItems: topItems,
    recentOrders: selected.take(6).toList(),
  );
}

List<TrendPoint> _createTrend(
  List<OrderModel> selected,
  AnalyticsRange range,
  DateTime now,
  DateTime? start,
) {
  // Daily buckets for 7 days, weekly buckets for 30/90 days, and
  // calendar months for 365 days / all time.
  if (range == AnalyticsRange.sevenDays ||
      range == AnalyticsRange.thirtyDays ||
      range == AnalyticsRange.ninetyDays) {
    final totalDays = range.days!;
    final bucketWidth = totalDays == 7 ? 1 : 7;
    final count = (totalDays / bucketWidth).ceil();
    final counts = List<int>.filled(count, 0);
    final revenues = List<int>.filled(count, 0);
    for (final order in selected) {
      final dayIndex = _calendarDaysBetween(order.orderTime, start!);
      final bucket = dayIndex ~/ bucketWidth;
      if (bucket >= 0 && bucket < count) {
        counts[bucket]++;
        revenues[bucket] += order.totalPriceCents;
      }
    }
    return List.generate(count, (i) {
      final day = DateTime(start!.year, start.month,
          start.day + i * bucketWidth);
      return TrendPoint('${day.month}/${day.day}', counts[i], revenues[i]);
    });
  }

  final DateTime firstMonth;
  if (range == AnalyticsRange.oneYear && start != null) {
    firstMonth = DateTime(start.year, start.month);
  } else if (selected.isNotEmpty) {
    final earliest = selected
        .map((order) => order.orderTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    firstMonth = DateTime(earliest.year, earliest.month);
  } else {
    firstMonth = DateTime(now.year, now.month - 11);
  }
  final monthCount = math.max(1,
      (now.year - firstMonth.year) * 12 + now.month - firstMonth.month + 1);
  final counts = List<int>.filled(monthCount, 0);
  final revenues = List<int>.filled(monthCount, 0);
  for (final order in selected) {
    final i = (order.orderTime.year - firstMonth.year) * 12 +
        order.orderTime.month - firstMonth.month;
    if (i >= 0 && i < monthCount) {
      counts[i]++;
      revenues[i] += order.totalPriceCents;
    }
  }
  return List.generate(monthCount, (i) {
    final month = DateTime(firstMonth.year, firstMonth.month + i);
    return TrendPoint('${month.month}/${month.year % 100}',
        counts[i], revenues[i]);
  });
}
