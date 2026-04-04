import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final profilePhotoProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        final raw = snap.data()?['photoBase64'] as String?;
        // Guard against oversized or corrupted base64 strings
        if (raw != null && raw.length > 500000) return null;
        return raw;
      });
});

class ProfilePhotoService {
  static Future<String?> pickAndEncode(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (picked == null) return null;
    final bytes = await File(picked.path).readAsBytes();
    return base64Encode(bytes);
  }

  static Future<void> save(String uid, String base64Photo) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'photoBase64': base64Photo}, SetOptions(merge: true));
  }
}
