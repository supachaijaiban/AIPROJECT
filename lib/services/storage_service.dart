import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadReceipt({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // Storage object keys must be ASCII — drop the original name (often Thai)
    // and keep only its extension.
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex == -1 ? '' : fileName.substring(dotIndex);
    final safeExtension = RegExp(r'^\.[A-Za-z0-9]{1,5}$').hasMatch(extension) ? extension : '.jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$safeExtension';

    await _client.storage.from('receipts').uploadBinary(path, bytes);
    return _client.storage.from('receipts').createSignedUrl(path, 60 * 60 * 24 * 365);
  }
}
