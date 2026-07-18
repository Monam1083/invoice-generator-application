import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../database/hive_service.dart';
import '../../models/business_info.dart';
import '../../models/customer_info.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_status.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/product_item_card.dart';

/// Screen used both to create a brand-new invoice and to edit an existing
/// one. Pass an [existingInvoice] to edit; leave it null to create new.
class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? existingInvoice;

  const CreateInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _dateFmt = DateFormat('dd MMM yyyy');

  // Business
  final businessNameCtrl = TextEditingController();
  final businessAddressCtrl = TextEditingController();
  final businessEmailCtrl = TextEditingController();
  final businessPhoneCtrl = TextEditingController();

  // Customer
  final customerNameCtrl = TextEditingController();
  final customerAddressCtrl = TextEditingController();
  final customerEmailCtrl = TextEditingController();
  final customerPhoneCtrl = TextEditingController();

  // Item entry fields
  final productCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  final taxCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  final List<InvoiceItem> items = [];
  InvoiceStatus status = InvoiceStatus.unpaid;

  String currencySymbol = '\$';
  String? invoiceNumber;
  String? existingId;
  bool get isEditing => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    final settings = HiveService.getSettings();
    currencySymbol = settings.currencySymbol;
    taxCtrl.text = settings.defaultTaxPercent.toString();

    if (isEditing) {
      final inv = widget.existingInvoice!;
      existingId = inv.id;
      invoiceNumber = inv.invoiceNumber;
      businessNameCtrl.text = inv.business.name;
      businessAddressCtrl.text = inv.business.address;
      businessEmailCtrl.text = inv.business.email;
      businessPhoneCtrl.text = inv.business.phone;
      customerNameCtrl.text = inv.customer.name;
      customerAddressCtrl.text = inv.customer.address;
      customerEmailCtrl.text = inv.customer.email;
      customerPhoneCtrl.text = inv.customer.phone;
      invoiceDate = inv.invoiceDate;
      dueDate = inv.dueDate;
      items.addAll(inv.items);
      taxCtrl.text = inv.taxPercent.toString();
      notesCtrl.text = inv.notes;
      status = inv.status;
      currencySymbol = inv.currencySymbol;
    } else {
      businessNameCtrl.text = settings.business.name;
      businessAddressCtrl.text = settings.business.address;
      businessEmailCtrl.text = settings.business.email;
      businessPhoneCtrl.text = settings.business.phone;
    }
  }

  @override
  void dispose() {
    businessNameCtrl.dispose();
    businessAddressCtrl.dispose();
    businessEmailCtrl.dispose();
    businessPhoneCtrl.dispose();
    customerNameCtrl.dispose();
    customerAddressCtrl.dispose();
    customerEmailCtrl.dispose();
    customerPhoneCtrl.dispose();
    productCtrl.dispose();
    quantityCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    taxCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get taxPercent => double.tryParse(taxCtrl.text.trim()) ?? 0;
  double get taxAmount => subtotal * (taxPercent / 100);
  double get grandTotal => subtotal + taxAmount;

  Future<void> _pickDate({required bool isInvoiceDate}) async {
    final initial = isInvoiceDate ? invoiceDate : dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          invoiceDate = picked;
        } else {
          dueDate = picked;
        }
      });
    }
  }

  void _addItem() {
    final name = productCtrl.text.trim();
    final qty = double.tryParse(quantityCtrl.text.trim());
    final price = double.tryParse(priceCtrl.text.trim());
    final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || qty == null || qty <= 0 || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid product name, quantity and price')),
      );
      return;
    }

    setState(() {
      items.add(InvoiceItem(
        id: _uuid.v4(),
        name: name,
        quantity: qty,
        unitPrice: price,
        discountPercent: discount,
      ));
      productCtrl.clear();
      quantityCtrl.text = '1';
      priceCtrl.clear();
      discountCtrl.clear();
    });
  }

  void _removeItem(String id) {
    setState(() => items.removeWhere((e) => e.id == id));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product or service')),
      );
      return;
    }

    final number = invoiceNumber ?? await HiveService.nextInvoiceNumber();

    final invoice = InvoiceModel(
      id: existingId ?? _uuid.v4(),
      invoiceNumber: number,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      business: BusinessInfo(
        name: businessNameCtrl.text.trim(),
        address: businessAddressCtrl.text.trim(),
        email: businessEmailCtrl.text.trim(),
        phone: businessPhoneCtrl.text.trim(),
        logoPath: HiveService.getSettings().business.logoPath,
      ),
      customer: CustomerInfo(
        name: customerNameCtrl.text.trim(),
        address: customerAddressCtrl.text.trim(),
        email: customerEmailCtrl.text.trim(),
        phone: customerPhoneCtrl.text.trim(),
      ),
      items: items,
      taxPercent: taxPercent,
      notes: notesCtrl.text.trim(),
      status: status,
      currencySymbol: currencySymbol,
      createdAt: isEditing ? widget.existingInvoice!.createdAt : DateTime.now(),
    );

    await HiveService.saveInvoice(invoice);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEditing ? 'Invoice updated' : 'Invoice saved ✅')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Invoice' : 'Create Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invoiceNumber != null) ...[
                Text('Invoice #$invoiceNumber',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 16),
              ],

              _sectionTitle('Invoice Dates'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Invoice Date',
                      value: _dateFmt.format(invoiceDate),
                      onTap: () => _pickDate(isInvoiceDate: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Due Date',
                      value: _dateFmt.format(dueDate),
                      onTap: () => _pickDate(isInvoiceDate: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionTitle('Business Information'),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Company Name',
                hintText: 'Your company name',
                controller: businessNameCtrl,
                icon: Icons.business,
                validator: (v) => Validators.required(v, field: 'Company name'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Address',
                hintText: 'Company address',
                controller: businessAddressCtrl,
                icon: Icons.location_on_outlined,
                validator: (v) => Validators.required(v, field: 'Business address'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Email',
                hintText: 'company@email.com',
                controller: businessEmailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Phone Number',
                hintText: '+1 555 000 0000',
                controller: businessPhoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),

              const SizedBox(height: 24),
              _sectionTitle('Customer Information'),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Customer Name',
                hintText: 'Customer name',
                controller: customerNameCtrl,
                icon: Icons.person_outline,
                validator: (v) => Validators.required(v, field: 'Customer name'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Address',
                hintText: 'Customer address',
                controller: customerAddressCtrl,
                icon: Icons.location_on_outlined,
                validator: (v) => Validators.required(v, field: 'Customer address'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Email',
                hintText: 'customer@email.com',
                controller: customerEmailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.email(v, optional: true),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Phone Number',
                hintText: '+1 555 000 0000',
                controller: customerPhoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.phone(v, optional: true),
              ),

              const SizedBox(height: 24),
              _sectionTitle('Add Product / Service'),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Name',
                hintText: 'Product or service name',
                controller: productCtrl,
                icon: Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: 'Quantity',
                      hintText: '1',
                      controller: quantityCtrl,
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      labelText: 'Unit Price',
                      hintText: '0.00',
                      controller: priceCtrl,
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Discount % (optional)',
                hintText: '0',
                controller: discountCtrl,
                icon: Icons.percent,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CustomButton(text: 'Add Item', icon: Icons.add, onPressed: _addItem),

              if (items.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Items (${items.length})'),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => ProductItemCard(
                    item: item,
                    currencySymbol: currencySymbol,
                    onDelete: () => _removeItem(item.id),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _sectionTitle('Tax & Notes'),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Tax %',
                hintText: '0',
                controller: taxCtrl,
                icon: Icons.percent,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Notes / Payment Instructions',
                hintText: 'e.g. Payable within 7 days via bank transfer',
                controller: notesCtrl,
                icon: Icons.notes,
                maxLines: 3,
              ),

              const SizedBox(height: 12),
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.title)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: InvoiceStatus.values.map((s) {
                  final selected = status == s;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) => setState(() => status = s),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.title,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', subtotal),
                    _summaryRow('Tax', taxAmount),
                    const Divider(),
                    _summaryRow('Grand Total', grandTotal, bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              CustomButton(
                text: isEditing ? 'Update Invoice' : 'Save Invoice',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.title,
        ),
      );

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 17 : 14,
              )),
          Text(
            '$currencySymbol${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: bold ? 18 : 14,
              color: bold ? AppColors.primary : AppColors.title,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
        ),
        child: Text(value),
      ),
    );
  }
}
