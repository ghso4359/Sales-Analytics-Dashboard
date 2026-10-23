class DemoProduct {
  final String sku;
  final String name;
  final String category;
  final int unitPriceCents;

  const DemoProduct(this.sku, this.name, this.category, this.unitPriceCents);
}

/// Retail catalogue used for the live "Add test order" control.
/// Test-order prices are taken from here, never typed into an analytics total.
const List<DemoProduct> demoProducts = [
  DemoProduct('ELEC-01', 'Wireless Mouse', 'Electronics', 2990),
  DemoProduct('ELEC-02', 'USB-C Cable', 'Electronics', 1590),
  DemoProduct('ELEC-03', 'Bluetooth Headphones', 'Electronics', 7990),
  DemoProduct('OFF-01', 'A5 Notebook', 'Office', 850),
  DemoProduct('OFF-02', 'Desk Organiser', 'Office', 2490),
  DemoProduct('OFF-03', 'Gel Pen Set', 'Office', 1290),
  DemoProduct('LIFE-01', 'Insulated Bottle', 'Lifestyle', 3490),
  DemoProduct('LIFE-02', 'Canvas Tote Bag', 'Lifestyle', 1990),
];
