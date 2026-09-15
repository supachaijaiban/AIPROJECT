import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadReceipt({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('receipts').uploadBinary(path, bytes);
    return _client.storage.from('receipts').createSignedUrl(path, 60 * 60 * 24 * 365);
  }
}
