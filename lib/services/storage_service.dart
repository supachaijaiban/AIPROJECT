import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadReceipt({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ref = _storage
        .ref()
        .child('receipts')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final task = await ref.putData(bytes);
    return task.ref.getDownloadURL();
  }
}
