import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/models.dart';
import '../../shared/widgets.dart';

/// Client-side invoice PDF (same idea as website `invoicePdf.ts`).
Future<void> shareOrderInvoicePdf(OrderModel order) async {
  final doc = pw.Document();
  final invoiceNo = order.displayId;
  final date = formatOrderDateTime(order.createdAt);
  final bill = order.addressLine(order.billingAddress) ?? '—';
  final ship = order.addressLine(order.shippingAddress) ?? '—';
  final subtotal = order.subtotal ??
      order.items.fold<double>(0, (s, e) => s + e.lineTotal);
  final delivery = order.deliveryFee ?? 0;
  final discount = (order.discount ?? 0) + (order.couponDiscount ?? 0);
  final tax = order.salesTax ?? 0;
  final total = order.displayTotal;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Gher Tak — Your Shopping Destination',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.Text(
                  'www.ghertak.com',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Invoice #', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  invoiceNo,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (date.isNotEmpty)
                  pw.Text(
                    'Date: $date',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    order.customerName ?? 'Customer',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if ((order.customerContact ?? '').isNotEmpty)
                    pw.Text(
                      order.customerContact!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.Text(bill, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Ship To',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(ship, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Qty', 'Price', 'Total'],
          data: [
            for (final item in order.items)
              [
                item.variationLabel == null || item.variationLabel!.isEmpty
                    ? item.name
                    : '${item.name}\n${item.variationLabel}',
                '${item.quantity}',
                formatRs(item.price),
                formatRs(item.lineTotal),
              ],
          ],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF11788C)),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.4),
            3: const pw.FlexColumnWidth(1.4),
          },
        ),
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 200,
            child: pw.Column(
              children: [
                _totalRow('Subtotal', formatRs(subtotal)),
                if (discount > 0) _totalRow('Discount', '-${formatRs(discount)}'),
                if (delivery > 0)
                  _totalRow('Delivery', formatRs(delivery))
                else
                  _totalRow('Delivery', 'Complimentary'),
                if (tax > 0) _totalRow('Tax', formatRs(tax)),
                pw.Divider(color: PdfColors.grey400),
                _totalRow('Total', formatRs(total), bold: true),
                if ((order.paymentGateway ?? '').isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        'Payment: ${order.paymentGateway}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 28),
        pw.Text(
          'Thank you for shopping with Gher Tak.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          'Support: info@ghertak.com',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'GherTak-Invoice-$invoiceNo.pdf',
  );
}

pw.Widget _totalRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
