import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../services/claim_repository.dart';

class UploadReceiptPage extends StatefulWidget {
  const UploadReceiptPage({super.key});

  @override
  State<UploadReceiptPage> createState() => _UploadReceiptPageState();
}

class _UploadReceiptPageState extends State<UploadReceiptPage> {
  final _amountController = TextEditingController();
  String? _category;
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _submitting = false;
  String? _error;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file;
      _pickedBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final user = context.read<AppState>().currentUser!;
    final amount = double.tryParse(_amountController.text);

    if (_pickedBytes == null || _category == null || amount == null || amount <= 0) {
      setState(() => _error = 'กรุณากรอกข้อมูลให้ครบและแนบรูปใบเสร็จ');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ClaimRepository().submitClaim(
        user: user,
        category: _category!,
        requestedAmount: amount,
        fileName: _pickedFile!.name,
        receiptBytes: _pickedBytes!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'ส่งคำขอไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('ยื่นขอเบิกค่าใช้จ่าย')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pickedBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_pickedBytes!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo),
            label: Text(_pickedBytes == null ? 'แนบรูปใบเสร็จ' : 'เปลี่ยนรูปใบเสร็จ'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'ประเภทค่าใช้จ่าย'),
            items: user.allowedCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'ยอดเงิน (บาท)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ส่งคำขอ'),
          ),
        ],
      ),
    );
  }
}
