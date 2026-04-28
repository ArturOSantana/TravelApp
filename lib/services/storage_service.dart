import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload de foto para o Storage
  static Future<String> uploadPhoto({
    required File photo,
    required String tripId,
    String folder = 'journal',
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(photo.path)}';
      final String storagePath = 'trips/$tripId/$folder/$fileName';

      final Reference ref = _storage.ref().child(storagePath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'tripId': tripId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putFile(photo, metadata);

      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Foto enviada com sucesso: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Erro ao enviar foto: $e');
      rethrow;
    }
  }

  /// Upload de múltiplas fotos -> Vê se funciona dps
  static Future<List<String>> uploadMultiplePhotos({
    required List<File> photos,
    required String tripId,
    String folder = 'journal',
    Function(int current, int total)? onProgress,
  }) async {
    List<String> urls = [];

    for (int i = 0; i < photos.length; i++) {
      try {
        final url = await uploadPhoto(
          photo: photos[i],
          tripId: tripId,
          folder: folder,
        );
        urls.add(url);

        if (onProgress != null) {
          onProgress(i + 1, photos.length);
        }
      } catch (e) {
        print('[ERROR] Erro ao enviar foto ${i + 1}: $e');
      }
    }

    return urls;
  }

  static Future<void> deletePhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      print(' Foto deletada com sucesso');
    } catch (e) {
      print(' Erro ao deletar foto: $e');
      rethrow;
    }
  }

  static Future<void> deleteMultiplePhotos(List<String> photoUrls) async {
    for (String url in photoUrls) {
      try {
        await deletePhoto(url);
      } catch (e) {
        print(' Erro ao deletar foto: $e');
      }
    }
  }

  /// Selecionar foto da galeria -> deu erro em uma versoes atras
  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('[ERROR] Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Tirar foto com a câmera -> deu erro em uma versoes atras
  static Future<File?> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('[ERROR] Erro ao tirar foto: $e');
      return null;
    }
  }

  /// Selecionar múltiplas fotos
  static Future<List<File>> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      print('Erro ao selecionar imagens: $e');
      return [];
    }
  }

  static Future<List<File>> pickMultiplePhotos() async {
    return pickMultipleImages();
  }

  static String getThumbnailUrl(String originalUrl, {String size = '200x200'}) {
    final uri = Uri.parse(originalUrl);
    final pathSegments = uri.pathSegments.toList();
    final lastSegment = pathSegments.last;
    final parts = lastSegment.split('.');

    if (parts.length > 1) {
      final name = parts.sublist(0, parts.length - 1).join('.');
      final extension = parts.last;
      pathSegments[pathSegments.length - 1] = '${name}_${size}.$extension';
    }

    return uri.replace(pathSegments: pathSegments).toString();
  }
}
