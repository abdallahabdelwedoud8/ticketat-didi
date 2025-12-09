import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/payment_service.dart';
import 'package:eventide/services/ticket_service.dart';
import 'package:eventide/services/event_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final EventModel event;
  final int quantity;
  final double totalPrice;
  final double discount;
  final String userId;
  final bool fromPrivateEvent;
  final String? selectedTierName;

  PaymentScreen({
    super.key,
    required this.event,
    this.quantity = 1,
    double? totalPrice,
    this.discount = 0,
    String? userId,
    this.fromPrivateEvent = false,
    this.selectedTierName,
  }) : totalPrice = totalPrice ?? event.price,
       userId = userId ?? '';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  final _senderNumberController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _screenshotPath;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.totalPrice * widget.quantity;
    final feePerTicket = FeeCalculator.calculateBuyerFee(widget.totalPrice, widget.event.organizerIsPartner);
    final totalFees = feePerTicket * widget.quantity;
    final totalBeforeDiscount = subtotal + totalFees;
    final discountAmount = totalBeforeDiscount * widget.discount;
    final finalPrice = totalBeforeDiscount - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.whiteColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (widget.selectedTierName != null) ...[
                      const SizedBox(height: 4),
                      Text('Tier: ${widget.selectedTierName}', style: const TextStyle(fontSize: 14, color: AppConstants.primaryColor, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 12),
                    _buildPriceRow('Base Price', '${widget.quantity} × ${widget.totalPrice.toStringAsFixed(0)} MRU', subtotal.toStringAsFixed(0)),
                    const SizedBox(height: 8),
                    _buildPriceRow('Platform Fee', '${widget.quantity} × ${feePerTicket.toStringAsFixed(0)} MRU', totalFees.toStringAsFixed(0), isFee: true),
                    const Divider(height: 20),
                    _buildPriceRow('Subtotal', '', totalBeforeDiscount.toStringAsFixed(0)),
                    if (widget.discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow('First Purchase Discount (${(widget.discount * 100).toStringAsFixed(0)}%)', '', '-${discountAmount.toStringAsFixed(0)}', isDiscount: true),
                    ],
                    const Divider(height: 24),
                    _buildPriceRow('Total', '', '${finalPrice.toStringAsFixed(0)} MRU', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(PaymentMethod.mobileMoney, 'Mobile Money', Icons.phone_android, 'Pay via Sedad, Bimbank, Bankily'),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(PaymentMethod.card, 'Card Payment', Icons.credit_card, 'Pay with credit/debit card'),
            const SizedBox(height: 24),
            if (_selectedMethod == PaymentMethod.mobileMoney) _buildMobileMoneyForm() else _buildCardPaymentForm(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Payment', style: TextStyle(color: AppConstants.whiteColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String details, String amount, {bool isDiscount = false, bool isTotal = false, bool isFee = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
              if (details.isNotEmpty) Text(details, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.green : (isFee ? Colors.orange : AppConstants.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, String title, IconData icon, String description) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppConstants.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(description, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    final subtotal = widget.totalPrice * widget.quantity;
    final feePerTicket = FeeCalculator.calculateBuyerFee(widget.totalPrice, widget.event.organizerIsPartner);
    final totalFees = feePerTicket * widget.quantity;
    final totalBeforeDiscount = subtotal + totalFees;
    final discountAmount = totalBeforeDiscount * widget.discount;
    final finalPrice = totalBeforeDiscount - discountAmount;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 Payment Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (widget.event.paymentOptions.isEmpty)
                    Text(AppConstants.defaultMobileMoneyNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor))
                  else
                    ...widget.event.paymentOptions.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('${option.provider}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(option.accountNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        ],
                      ),
                    )),
                  const SizedBox(height: 8),
                  Text('Amount: ${finalPrice.toStringAsFixed(0)} MRU', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('💳 Please send payment to any of the accounts above', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('After sending the payment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: _senderNumberController,
              decoration: InputDecoration(
                labelText: 'Your Mobile Number',
                hintText: '+222 XX XX XX XX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Transaction Reference ID',
                hintText: 'Enter the transaction ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Upload Payment Screenshot:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickScreenshot,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file, color: AppConstants.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _screenshotPath != null ? 'Screenshot uploaded ✓' : 'Tap to upload screenshot',
                        style: TextStyle(color: _screenshotPath != null ? Colors.green : AppConstants.greyColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('⚠️ Your payment will be verified within 24 hours', style: TextStyle(fontSize: 12, color: AppConstants.greyColor, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'Name on card',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _screenshotPath = result.files.first.path ?? result.files.first.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == PaymentMethod.mobileMoney) {
      if (_senderNumberController.text.isEmpty || _referenceController.text.isEmpty || _screenshotPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields and upload screenshot'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // Purchase all tickets at once with tier and quantity
      final ticket = await TicketService.purchaseTicket(
        widget.userId,
        widget.event.eventId,
        tierName: widget.selectedTierName,
        quantity: widget.quantity,
      );
      
      if (ticket == null) {
        throw Exception('Failed to purchase ticket - event may be sold out or tier unavailable');
      }
      
      // Create payment proof
      await PaymentService.createPaymentProof(
        ticketId: ticket.ticketId,
        method: _selectedMethod,
        screenshotUrl: _screenshotPath,
        senderNumber: _senderNumberController.text,
        transactionReference: _referenceController.text,
      );
      
      final List<String> ticketIds = [ticket.ticketId];

      if (!mounted) return;
      
      // Auto-download tickets
      await _autoDownloadTickets(ticketIds);
      
      Navigator.pop(context, true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedMethod == PaymentMethod.mobileMoney
              ? 'Payment submitted! Your tickets have been downloaded and will be activated once payment is verified (within 24h)'
              : 'Payment successful! ${widget.quantity} ticket(s) purchased and downloaded'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _autoDownloadTickets(List<String> ticketIds) async {
    try {
      for (final ticketId in ticketIds) {
        final ticket = await TicketService.getTicketById(ticketId);
        if (ticket != null) {
          await _generateAndShareTicket(ticket);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<void> _generateAndShareTicket(TicketModel ticket) async {
    try {
      final event = await EventService.getEventById(ticket.eventId);
      if (event == null) return;
      
      final ticketText = '''
🎟️ TICKETAT - DIGITAL TICKET
━━━━━━━━━━━━━━━━━━━━━━━━

Event: ${event.title}
Date: ${DateFormat('EEEE, dd MMMM yyyy').format(event.date)}
Time: ${DateFormat('HH:mm').format(event.date)}
Venue: ${event.venue}, Mauritanie

Ticket ID: ${ticket.ticketId}
Price Paid: ${ticket.pricePaid.toStringAsFixed(0)} MRU
Status: ${ticket.status.toString().split('.').last.toUpperCase()}

Barcode: ${ticket.qrData}

⚠️ Note: Bring this digital ticket or show your barcode to enter the event

Powered by Ticketat
''';
      
      await Share.share(
        ticketText,
        subject: 'Your Ticket for ${event.title}',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _senderNumberController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
