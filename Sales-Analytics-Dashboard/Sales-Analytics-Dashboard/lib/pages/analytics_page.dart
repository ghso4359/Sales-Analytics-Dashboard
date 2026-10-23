import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sales_analytics_dashboard/data/product_catalog.dart';
import 'package:sales_analytics_dashboard/models/mock_orders.dart';
import 'package:sales_analytics_dashboard/models/orderModel.dart';
import 'package:sales_analytics_dashboard/services/analytics_calculator.dart';

const Color primary = Color(0xFF6366F1);
const Color bgColor = Color(0xFFF8F9FB);
const Color textSecondary = Color(0xFF6B7280);

String _money(num cents) {
  final value = (cents / 100).toStringAsFixed(2);
  final parts = value.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '\$${buffer.toString()}.${parts[1]}';
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<OrderModel>? _orders;
  List<OrderModel> _originalOrders = [];
  String? _error;
  AnalyticsRange _range = AnalyticsRange.thirtyDays;
  String _selectedSku = demoProducts.first.sku;
  int _quantity = 1;
  int _demoSequence = 0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final result = await loadMockOrders();
      if (!mounted) return;
      setState(() {
        _originalOrders = List.of(result);
        _orders = List.of(result);
        _error = null;
        _demoSequence = 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  void _addTestOrder() {
    final product = demoProducts.firstWhere((item) => item.sku == _selectedSku);
    final now = DateTime.now();
    setState(() {
      _demoSequence++;
      _orders = [
        ...?_orders,
        OrderModel(
          id: 'DEMO-${_demoSequence.toString().padLeft(3, '0')}',
          customerId: 'DEMO-CUSTOMER-$_demoSequence',
          customerName: 'Demo Customer $_demoSequence',
          orderTime: now,
          status: OrderStatus.completed,
          items: [
            OrderItem(
              sku: product.sku,
              name: product.name,
              category: product.category,
              unitPriceCents: product.unitPriceCents,
              quantity: _quantity,
            ),
          ],
        ),
      ];
    });
  }

  void _resetTestOrders() {
    setState(() {
      _orders = List.of(_originalOrders);
      _demoSequence = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final snapshot = orders == null ? null : calculateAnalytics(orders, _range);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Analytics', style: TextStyle(
          color: Colors.black, fontWeight: FontWeight.bold,
        )),
      ),
      body: orders == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Could not load sample orders'),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                    FilledButton(onPressed: _loadOrders, child: const Text('Retry')),
                  ],
                ))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 18),
                      _buildFilter(),
                      const SizedBox(height: 12),
                      Row(children: [
                        _statCard('Sales', _money(snapshot!.totalRevenueCents),
                            snapshot.revenueChange, Icons.attach_money, Colors.amber),
                        _statCard('Orders', '${snapshot.totalOrders}',
                            snapshot.ordersChange, Icons.shopping_bag, Colors.blue),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _statCard('Customers', '${snapshot.uniqueCustomers}',
                            snapshot.customersChange, Icons.people, Colors.green),
                        _statCard('Avg Order', _money(snapshot.averageOrderCents),
                            snapshot.averageChange, Icons.receipt_long, Colors.purple),
                      ]),
                      const SizedBox(height: 22),
                      _sectionTitle('Sales Trend'),
                      _buildLineChartCard(snapshot),
                      const SizedBox(height: 22),
                      _sectionTitle('Orders'),
                      _buildBarChartCard(snapshot),
                      const SizedBox(height: 22),
                      _sectionTitle('Category'),
                      _buildPieChartCard(snapshot),
                      const SizedBox(height: 22),
                      _sectionTitle('Top Items'),
                      _buildTopItemsCard(snapshot),
                      const SizedBox(height: 22),
                      _sectionTitle('Test with a new order'),
                      _buildTestOrderCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Recent Completed Orders'),
                      _buildRecentCard(snapshot),
                      const SizedBox(height: 20),
                      const Center(child: Text(
                        'Demo only • All orders and customers are fictional',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildIntro() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Store Performance', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.bold,
      )),
      const SizedBox(height: 5),
      Text('${_originalOrders.length} sample orders loaded • '
          '$_demoSequence additional test orders',
          style: const TextStyle(color: textSecondary, fontSize: 12)),
    ],
  );

  Widget _buildFilter() => Row(
    children: [
      const Icon(Icons.calendar_today_outlined, size: 18, color: primary),
      const SizedBox(width: 10),
      const Text('Period', style: TextStyle(fontWeight: FontWeight.w600)),
      const Spacer(),
      DropdownButton<AnalyticsRange>(
        value: _range,
        underline: const SizedBox.shrink(),
        items: AnalyticsRange.values.map((range) => DropdownMenuItem(
          value: range, child: Text(range.label, style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: (range) {
          if (range == null) return;
          setState(() { _range = range; _touchedIndex = -1; });
        },
      ),
    ],
  );

  Widget _statCard(String label, String value, double? change,
      IconData icon, Color iconColor) {
    final available = change != null;
    final positive = (change ?? 0) >= 0;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(
            color: Color(0x09000000), blurRadius: 12, offset: Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(
              color: textSecondary, fontSize: 13,
            ))),
            Icon(icon, color: iconColor, size: 19),
          ]),
          const SizedBox(height: 9),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(!available ? Icons.remove : positive
                ? Icons.trending_up : Icons.trending_down,
                size: 15, color: !available ? textSecondary
                    : positive ? Colors.green : Colors.red),
            const SizedBox(width: 3),
            Flexible(child: Text(
              available ? '${positive ? '+' : ''}${change.toStringAsFixed(1)}%'
                  : 'N/A',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: !available ? textSecondary : positive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500, fontSize: 12,
              ),
            )),
          ]),
          Text(_range.comparisonLabel, maxLines: 2,
              style: const TextStyle(color: textSecondary, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600,
    )),
  );

  Widget _card(Widget child) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _chartTitle(double value, TitleMeta meta, {bool money = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(money ? '\$${value.round()}' : '${value.round()}',
          style: const TextStyle(color: textSecondary, fontSize: 10)),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta, List<TrendPoint> points) {
    final index = value.toInt();
    if (value != index.toDouble() || index < 0 || index >= points.length) {
      return const SizedBox.shrink();
    }
    final step = points.length > 12 ? 3 : points.length > 7 ? 2 : 1;
    if (index % step != 0 && index != points.length - 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Text(points[index].label,
          style: const TextStyle(color: textSecondary, fontSize: 10)),
    );
  }

  Widget _buildLineChartCard(AnalyticsSnapshot data) {
    final points = data.trend;
    final highest = points.fold<int>(0,
        (n, item) => math.max(n, item.revenueCents));
    final maxY = math.max(1.0, highest / 100 * 1.2);
    final interval = math.max(1.0, (maxY / 4).ceilToDouble());
    return _card(SizedBox(height: 242, child: LineChart(LineChartData(
      minX: 0,
      maxX: math.max(1, points.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) => _bottomTitle(value, meta, points),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 53, interval: interval,
          getTitlesWidget: (value, meta) => _chartTitle(value, meta, money: true),
        )),
      ),
      lineBarsData: [LineChartBarData(
        spots: [for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), points[i].revenueCents / 100)],
        isCurved: points.length > 2,
        barWidth: 3,
        color: primary,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true,
            color: const Color(0x266366F1)),
      )],
    ))));
  }

  Widget _buildBarChartCard(AnalyticsSnapshot data) {
    final points = data.trend;
    final highest = points.fold<int>(0,
        (n, item) => math.max(n, item.orderCount));
    final maxY = math.max(1.0, highest * 1.2);
    final interval = math.max(1.0, (maxY / 4).ceilToDouble());
    return _card(SizedBox(height: 242, child: BarChart(BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      barGroups: [for (var i = 0; i < points.length; i++)
        BarChartGroupData(x: i, barRods: [BarChartRodData(
          toY: points[i].orderCount.toDouble(),
          width: points.length > 13 ? 11 : 18,
          color: primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        )])],
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 34,
          getTitlesWidget: (value, meta) => _bottomTitle(value, meta, points),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 40, interval: interval,
          getTitlesWidget: _chartTitle,
        )),
      ),
    ))));
  }

  Widget _buildPieChartCard(AnalyticsSnapshot data) {
    final categories = data.categoryQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (categories.isEmpty) {
      return _card(const Text('No category data for the selected period.'));
    }
    final total = categories.fold<int>(0, (n, item) => n + item.value);
    return _card(Column(children: [
      SizedBox(height: 215, child: PieChart(PieChartData(
        sections: [for (var i = 0; i < categories.length; i++)
          PieChartSectionData(
            value: categories[i].value.toDouble(),
            color: Colors.primaries[i % Colors.primaries.length],
            radius: i == _touchedIndex ? 70 : 62,
            title: '${(categories[i].value / total * 100).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,
            ),
          )],
        sectionsSpace: 3,
        centerSpaceRadius: 37,
        pieTouchData: PieTouchData(touchCallback: (event, response) {
          final next = !event.isInterestedForInteractions ||
                  response?.touchedSection == null
              ? -1 : response!.touchedSection!.touchedSectionIndex;
          if (next != _touchedIndex) setState(() => _touchedIndex = next);
        }),
      ))),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 7, children: [
        for (var i = 0; i < categories.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 10, width: 10, decoration: BoxDecoration(
              color: Colors.primaries[i % Colors.primaries.length],
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(width: 6),
            Text('${categories[i].key} (${categories[i].value})',
                style: const TextStyle(fontSize: 12)),
          ]),
      ]),
    ]));
  }

  Widget _buildTopItemsCard(AnalyticsSnapshot data) => _card(
    data.topItems.isEmpty
        ? const Text('No sold items for this period.')
        : Column(children: [for (var i = 0;
              i < math.min(data.topItems.length, 5); i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: primary,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
              title: Text(data.topItems[i].name, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text('${data.topItems[i].quantity} units sold'),
              trailing: Text(_money(data.topItems[i].revenueCents),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
  );

  Widget _buildTestOrderCard() {
    final current = demoProducts.firstWhere((item) => item.sku == _selectedSku);
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Add a fictional completed order and see every chart update.',
          style: TextStyle(color: textSecondary, fontSize: 12)),
      const SizedBox(height: 13),
      DropdownButtonFormField<String>(
        value: _selectedSku,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
        items: demoProducts.map((item) => DropdownMenuItem(
          value: item.sku, child: Text('${item.name} (${_money(item.unitPriceCents)})',
              overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (sku) { if (sku != null) setState(() => _selectedSku = sku); },
      ),
      const SizedBox(height: 12),
      Row(children: [
        const Text('Quantity'),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _quantity,
          items: [1, 2, 3, 4, 5].map((q) => DropdownMenuItem(
            value: q, child: Text('$q'),
          )).toList(),
          onChanged: (qty) { if (qty != null) setState(() => _quantity = qty); },
        ),
        const Spacer(),
        Text('Total: ${_money(current.unitPriceCents * _quantity)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 8, children: [
        FilledButton.icon(onPressed: _addTestOrder,
          icon: const Icon(Icons.add), label: const Text('Add test order')),
        OutlinedButton.icon(onPressed: _demoSequence == 0 ? null : _resetTestOrders,
          icon: const Icon(Icons.restart_alt), label: const Text('Reset')),
      ]),
    ]));
  }

  Widget _buildRecentCard(AnalyticsSnapshot data) => _card(
    data.recentOrders.isEmpty
        ? const Text('No completed orders in this period.')
        : Column(children: [for (final order in data.recentOrders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(order.id, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${order.customerName} • '
                  '${order.orderTime.day}/${order.orderTime.month}/${order.orderTime.year}'),
              trailing: Text(_money(order.totalPriceCents),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
  );
}
