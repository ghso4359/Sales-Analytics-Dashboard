import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sales_analytics_dashboard/models/orderModel.dart';

/// Load realistic-looking but entirely fictional transactions from a JSON asset.
Future<List<OrderModel>> loadMockOrders({DateTime? now}) async {
  final raw = await rootBundle.loadString('assets/data/sample_orders.json');
  return parseMockOrders(raw, now: now);
}

List<OrderModel> parseMockOrders(String jsonString, {DateTime? now}) {
  final rows = jsonDecode(jsonString) as List<dynamic>;
  return rows
      .map((row) => OrderModel.fromJson(row as Map<String, dynamic>, now: now))
      .toList();
}
