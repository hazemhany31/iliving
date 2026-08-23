import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';

/// Centralized service for uploading and managing files in Firebase Storage.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FirebaseStorage? get _storage {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseStorage.instance;
      }
    } catch (e) {
      debugPrint('[StorageService] FirebaseStorage not initialized: $e');
    }
    return null;
  }

  /// Uploads raw bytes or a File object to [destinationPath] in Firebase Storage.
  ///
  /// [file] can be a `File`, `Uint8List`, or `String` (path).
  Future<String> upload({
    required String destinationPath,
    required dynamic file,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      if (kDemoMode || kDebugMode) {
        debugPrint('[StorageService] DEMO/DEBUG: Simulating file upload to $destinationPath');
        if (onProgress != null) {
          onProgress(0.5);
          await Future.delayed(const Duration(milliseconds: 300));
          onProgress(1.0);
        }
        return 'https://firebasestorage.googleapis.com/v0/b/demo-bucket.appspot.com/o/${Uri.encodeComponent(destinationPath)}?alt=media';
      }
      throw Exception('Firebase Storage is not initialized.');
    }

    final ref = storage.ref().child(destinationPath);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'uploadedBy': AuthService.instance.currentProfile?.uid ?? 'anonymous',
      },
    );

    UploadTask task;

    if (file is Uint8List) {
      task = ref.putData(file, metadata);
    } else if (file is File) {
      task = ref.putFile(file, metadata);
    } else if (file is String) {
      task = ref.putFile(File(file), metadata);
    } else {
      throw ArgumentError('Unsupported file type for upload: ${file.runtimeType}');
    }

    if (onProgress != null) {
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress.clamp(0.0, 1.0));
        }
      });
    }

    final snapshot = await task;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Uploads a payment proof / bank receipt to `/receipts/{paymentId}/{fileName}`.
  Future<String> uploadPaymentProof({
    required String paymentId,
    required dynamic file,
    String fileName = 'proof.jpg',
    void Function(double progress)? onProgress,
  }) async {
    final path = 'receipts/$paymentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return await upload(
      destinationPath: path,
      file: file,
      contentType: _getContentType(fileName),
      onProgress: onProgress,
    );
  }

  /// Uploads a KYC document to `/users/{userId}/kyc/{docType}_{fileName}`.
  Future<String> uploadKycDocument({
    required String userId,
    required String docType,
    required dynamic file,
    String fileName = 'document.pdf',
    void Function(double progress)? onProgress,
  }) async {
    final path = 'users/$userId/kyc/${docType}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return await upload(
      destinationPath: path,
      file: file,
      contentType: _getContentType(fileName),
      onProgress: onProgress,
    );
  }

  /// Uploads a user profile avatar to `/users/{userId}/avatar/{fileName}`.
  Future<String> uploadProfileAvatar({
    required String userId,
    required dynamic file,
    String fileName = 'avatar.jpg',
    void Function(double progress)? onProgress,
  }) async {
    final path = 'users/$userId/avatar/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return await upload(
      destinationPath: path,
      file: file,
      contentType: _getContentType(fileName),
      onProgress: onProgress,
    );
  }

  /// Deletes a file by its full download URL or storage path.
  Future<void> deleteFile(String urlOrPath) async {
    final storage = _storage;
    if (storage == null) return;
    try {
      Reference ref;
      if (urlOrPath.startsWith('http')) {
        ref = storage.refFromURL(urlOrPath);
      } else {
        ref = storage.ref().child(urlOrPath);
      }
      await ref.delete();
    } catch (e) {
      debugPrint('[StorageService] Error deleting file: $e');
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
