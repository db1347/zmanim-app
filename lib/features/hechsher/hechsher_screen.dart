import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/hechsher_database.dart';

/// Barcode → kosher certification lookup, with manual entry fallback.
class HechsherScreen extends StatefulWidget {
  const HechsherScreen({super.key});

  @override
  State<HechsherScreen> createState() => _HechsherScreenState();
}

class _HechsherScreenState extends State<HechsherScreen> {
  final _manualController = TextEditingController();
  KosherProduct? _product;
  String? _notFoundBarcode;
  bool _scannerOpen = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _lookup(String barcode) {
    if (barcode.trim().isEmpty) return;
    setState(() {
      _product = HechsherDatabase.findByBarcode(barcode);
      _notFoundBarcode = _product == null ? barcode.trim() : null;
      _scannerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('בדיקת כשרות')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_scannerOpen)
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    // The scanner fires per camera frame — dedupe so one
                    // physical scan triggers exactly one lookup.
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null &&
                        code.isNotEmpty &&
                        code != _lastScannedCode) {
                      _lastScannedCode = code;
                      _lookup(code);
                    }
                  },
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => setState(() {
                _scannerOpen = true;
                _product = null;
                _notFoundBarcode = null;
                _lastScannedCode = null;
              }),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('סריקת ברקוד'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualController,
            keyboardType: TextInputType.number,
            onSubmitted: _lookup,
            decoration: InputDecoration(
              hintText: 'או הקלידו ברקוד…',
              prefixIcon: const Icon(Icons.numbers),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _lookup(_manualController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_product != null) _ProductCard(product: _product!),
          if (_notFoundBarcode != null)
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ברקוד $_notFoundBarcode לא נמצא',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'המוצר עדיין לא במאגר. בדקו את סמל הכשרות שעל '
                      'האריזה, או פנו לגוף הכשרות המקומי.',
                      style:
                          TextStyle(color: scheme.onSecondaryContainer),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('דיווח על המוצר'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'תודה! דיווחי קהילה יתווספו בעדכון עתידי.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'מאגר הדגמה ראשוני — גרסת ייצור דורשת חיבור לנתוני גופי '
            'הכשרות (בד״ץ, רבנות, OU ועוד). תמיד בדקו את האריזה עצמה.',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final KosherProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(product.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('כשרות: ${product.hechsher}'),
            Text('סטטוס: ${product.status}'),
            const SizedBox(height: 8),
            Text(
              'ברקוד ${product.barcode}',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
