/// Kosher certification lookup.
///
/// IMPORTANT: there is no unified public API for kosher certification.
/// This ships with a small starter dataset so the flow works end-to-end;
/// production needs a real data-aggregation backend (OU, OK, Star-K,
/// Chief Rabbinate, local agencies) plus moderated community corrections.
class KosherProduct {
  final String barcode;
  final String name;
  final String hechsher;
  final String status; // חלבי / פרווה / בשרי

  const KosherProduct({
    required this.barcode,
    required this.name,
    required this.hechsher,
    required this.status,
  });
}

class HechsherDatabase {
  const HechsherDatabase._();

  /// Common certification agencies for the acceptance filter.
  static const List<String> agencies = [
    'בד״ץ העדה החרדית',
    'הרבנות הראשית לישראל',
    'בד״ץ בית יוסף',
    'OU',
    'OK',
    'Star-K',
    'Kof-K',
    'CRC',
    'KLBD (לונדון)',
  ];

  /// Starter dataset — demonstration entries.
  static const List<KosherProduct> products = [
    KosherProduct(
        barcode: '7290000066318',
        name: 'במבה אסם',
        hechsher: 'בד״ץ העדה החרדית',
        status: 'פרווה'),
    KosherProduct(
        barcode: '7290000288024',
        name: 'שוקולד עלית',
        hechsher: 'הרבנות הראשית לישראל',
        status: 'חלבי'),
    KosherProduct(
        barcode: '0041196910184',
        name: 'מצות מנישביץ',
        hechsher: 'OU',
        status: 'פרווה'),
    KosherProduct(
        barcode: '0070920000459',
        name: 'מיץ ענבים קדם',
        hechsher: 'OU',
        status: 'פרווה'),
    KosherProduct(
        barcode: '7290004127342',
        name: 'חלב תנובה 3%',
        hechsher: 'הרבנות הראשית לישראל',
        status: 'חלבי'),
  ];

  static KosherProduct? findByBarcode(String barcode) {
    final clean = barcode.trim();
    for (final product in products) {
      if (product.barcode == clean) return product;
    }
    return null;
  }
}
