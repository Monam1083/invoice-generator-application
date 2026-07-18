import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../database/hive_service.dart';
import '../../models/app_settings.dart';
import '../../models/business_info.dart';
import '../../utils/currency_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final taxCtrl = TextEditingController();
  final prefixCtrl = TextEditingController();

  String currencyCode = 'USD';
  String? logoPath;

  @override
  void initState() {
    super.initState();
    final settings = HiveService.getSettings();
    nameCtrl.text = settings.business.name;
    addressCtrl.text = settings.business.address;
    emailCtrl.text = settings.business.email;
    phoneCtrl.text = settings.business.phone;
    taxCtrl.text = settings.defaultTaxPercent.toString();
    prefixCtrl.text = settings.invoicePrefix;
    currencyCode = settings.currencyCode;
    logoPath = settings.business.logoPath;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    taxCtrl.dispose();
    prefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final saved = await File(picked.path).copy('${dir.path}/company_logo.png');
    setState(() => logoPath = saved.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final current = HiveService.getSettings();
    final updated = current.copyWith(
      business: BusinessInfo(
        name: nameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        logoPath: logoPath,
      ),
      currencyCode: currencyCode,
      currencySymbol: CurrencyUtils.symbolFor(currencyCode),
      defaultTaxPercent: double.tryParse(taxCtrl.text.trim()) ?? 0,
      invoicePrefix: prefixCtrl.text.trim().isEmpty ? 'INV-' : prefixCtrl.text.trim(),
    );
    await HiveService.saveSettings(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Company Logo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(logoPath!), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_a_photo_outlined, color: AppColors.subtitle),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Company Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Company Name',
                hintText: 'Your company name',
                controller: nameCtrl,
                icon: Icons.business,
                validator: (v) => Validators.required(v, field: 'Company name'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Address',
                hintText: 'Company address',
                controller: addressCtrl,
                icon: Icons.location_on_outlined,
                validator: (v) => Validators.required(v, field: 'Address'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Email',
                hintText: 'company@email.com',
                controller: emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Phone Number',
                hintText: '+1 555 000 0000',
                controller: phoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),

              const SizedBox(height: 24),
              const Text('Invoice Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: currencyCode,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: CurrencyUtils.currencies.keys
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text('$code (${CurrencyUtils.currencies[code]})'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => currencyCode = value ?? currencyCode),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Default Tax %',
                hintText: '0',
                controller: taxCtrl,
                icon: Icons.percent,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                labelText: 'Invoice Prefix',
                hintText: 'INV-',
                controller: prefixCtrl,
                icon: Icons.tag,
              ),

              const SizedBox(height: 28),
              CustomButton(text: 'Save Settings', icon: Icons.save_outlined, onPressed: _save),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
