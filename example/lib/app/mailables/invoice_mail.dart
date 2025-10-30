import 'package:khadem/khadem.dart';

/// Invoice email with PDF attachment.
///
/// Example:
/// ```dart
/// final invoice = await generateInvoicePdf(orderId);
/// await Mail.send(InvoiceMail(
///   email: 'customer@example.com',
///   customerName: 'John Doe',
///   invoiceNumber: 'INV-2025-001',
///   amount: '\$99.99',
///   pdfPath: invoice.path,
/// ));
/// ```
class InvoiceMail extends Mailable {
  final String email;
  final String customerName;
  final String invoiceNumber;
  final String amount;
  final String pdfPath;

  InvoiceMail({
    required this.email,
    required this.customerName,
    required this.invoiceNumber,
    required this.amount,
    required this.pdfPath,
  });

  @override
  Future<void> build(MailerInterface mailer) async {
    mailer
        .to(email)
        .subject('Invoice $invoiceNumber')
        .html(_buildHtmlContent())
        .text(_buildTextContent())
        .attach(
          pdfPath,
          name: '$invoiceNumber.pdf',
          mimeType: 'application/pdf',
        );
  }

  String _buildHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #2196F3;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 0 0 5px 5px;
        }
        .invoice-details {
            background-color: white;
            padding: 15px;
            margin: 20px 0;
            border-left: 4px solid #2196F3;
        }
        .footer {
            margin-top: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📄 Invoice</h1>
        </div>
        <div class="content">
            <h2>Hello $customerName!</h2>
            <p>Thank you for your purchase. Please find your invoice attached to this email.</p>

            <div class="invoice-details">
                <h3>Invoice Details</h3>
                <p><strong>Invoice Number:</strong> $invoiceNumber</p>
                <p><strong>Amount:</strong> $amount</p>
                <p><strong>Date:</strong> ${DateTime.now().toString().split(' ')[0]}</p>
            </div>

            <p>The invoice is attached as a PDF document. If you have any questions about this invoice, please contact our support team.</p>

            <p>Thank you for your business!</p>

            <p>Best regards,<br>The Khadem Team</p>
        </div>
        <div class="footer">
            <p>This email was sent to $email</p>
            <p>© 2025 Khadem Framework. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildTextContent() {
    return '''
Invoice

Hello $customerName!

Thank you for your purchase. Please find your invoice attached to this email.

Invoice Details:
- Invoice Number: $invoiceNumber
- Amount: $amount
- Date: ${DateTime.now().toString().split(' ')[0]}

The invoice is attached as a PDF document. If you have any questions about this invoice, please contact our support team.

Thank you for your business!

Best regards,
The Khadem Team

This email was sent to $email
© 2025 Khadem Framework. All rights reserved.
''';
  }
}
