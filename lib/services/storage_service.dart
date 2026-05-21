import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../core/exceptions/app_exceptions.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const int _maxFileSizeBytes = 10 * 1024 * 1024;
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic'
  ];
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1080;
  static const int _imageQuality = 85;

  static Future<String> uploadPhoto({
    required File photo,
    required String tripId,
    String folder = 'journal',
    Function(double progress)? onProgress,
  }) async {
    _validateTripId(tripId);
    await _validateFile(photo);

    try {
      final String fileName = _generateFileName(photo.path);
      final String storagePath = 'trips/$tripId/$folder/$fileName';

      final Reference ref = _storage.ref().child(storagePath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(photo.path),
        customMetadata: {
          'tripId': tripId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'folder': folder,
        },
      );

      final UploadTask uploadTask = ref.putFile(photo, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e);
    } catch (e) {
      throw StorageException(
        'Erro inesperado ao enviar foto',
        code: 'upload_error',
        originalError: e,
      );
    }
  }

  static Future<List<String>> uploadMultiplePhotos({
    required List<File> photos,
    required String tripId,
    String folder = 'journal',
    Function(int current, int total)? onProgress,
    Function(int index, String error)? onError,
  }) async {
    if (photos.isEmpty) {
      throw ValidationException('Lista de fotos não pode estar vazia');
    }

    _validateTripId(tripId);

    final List<String> urls = [];
    final List<String> errors = [];

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
        final errorMsg = 'Erro ao enviar foto ${i + 1}: ${e.toString()}';
        errors.add(errorMsg);

        if (onError != null) {
          onError(i, e.toString());
        }
      }
    }

    // Se nenhuma foto foi enviada com sucesso, lançar exceção
    if (urls.isEmpty && errors.isNotEmpty) {
      throw StorageException(
        'Falha ao enviar todas as fotos: ${errors.join("; ")}',
        code: 'all_uploads_failed',
      );
    }

    return urls;
  }

  static Future<void> deletePhoto(String photoUrl) async {
    _validatePhotoUrl(photoUrl);

    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw _handleFirebaseStorageException(e);
    } catch (e) {
      throw StorageException(
        'Erro ao deletar foto',
        code: 'delete_error',
        originalError: e,
      );
    }
  }

  static Future<List<String>> deleteMultiplePhotos(
    List<String> photoUrls, {
    Function(int current, int total)? onProgress,
  }) async {
    if (photoUrls.isEmpty) {
      return [];
    }

    final List<String> failedUrls = [];

    for (int i = 0; i < photoUrls.length; i++) {
      try {
        await deletePhoto(photoUrls[i]);

        if (onProgress != null) {
          onProgress(i + 1, photoUrls.length);
        }
      } catch (e) {
        failedUrls.add(photoUrls[i]);
      }
    }

    return failedUrls;
  }

  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );

      if (image != null) {
        final file = File(image.path);
        await _validateFile(file);
        return file;
      }
      return null;
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw StorageException(
        'Erro ao selecionar imagem da galeria',
        code: 'gallery_pick_error',
        originalError: e,
      );
    }
  }

  static Future<File?> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );

      if (image != null) {
        final file = File(image.path);
        await _validateFile(file);
        return file;
      }
      return null;
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw StorageException(
        'Erro ao tirar foto',
        code: 'camera_error',
        originalError: e,
      );
    }
  }

  static Future<List<File>> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: _maxImageWidth.toDouble(),
        maxHeight: _maxImageHeight.toDouble(),
        imageQuality: _imageQuality,
      );

      final List<File> validFiles = [];

      for (final xFile in images) {
        try {
          final file = File(xFile.path);
          await _validateFile(file);
          validFiles.add(file);
        } catch (e) {
          // Ignora arquivos inválidos e continua
          continue;
        }
      }

      return validFiles;
    } catch (e) {
      throw StorageException(
        'Erro ao selecionar múltiplas imagens',
        code: 'multi_pick_error',
        originalError: e,
      );
    }
  }

  static Future<List<File>> pickMultiplePhotos() async {
    return pickMultipleImages();
  }

  static String getThumbnailUrl(String originalUrl, {String size = '200x200'}) {
    try {
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
    } catch (e) {
      // Se falhar ao gerar thumbnail URL, retorna original
      return originalUrl;
    }
  }

  static void _validateTripId(String tripId) {
    if (tripId.trim().isEmpty) {
      throw ValidationException('ID da viagem não pode estar vazio');
    }
  }

  static void _validatePhotoUrl(String photoUrl) {
    if (photoUrl.trim().isEmpty) {
      throw ValidationException('URL da foto não pode estar vazia');
    }

    try {
      final uri = Uri.parse(photoUrl);
      if (!uri.isAbsolute) {
        throw ValidationException('URL da foto deve ser absoluta');
      }
    } catch (e) {
      throw ValidationException('URL da foto inválida: ${e.toString()}');
    }
  }

  static Future<void> _validateFile(File file) async {
    // Verifica se arquivo existe
    if (!await file.exists()) {
      throw ValidationException('Arquivo não existe');
    }

    // Verifica tamanho do arquivo
    final fileSize = await file.length();
    if (fileSize > _maxFileSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      throw ValidationException(
        'Arquivo muito grande: ${sizeMB}MB. Máximo permitido: ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
      );
    }

    if (fileSize == 0) {
      throw ValidationException('Arquivo está vazio');
    }

    // Verifica extensão do arquivo
    final extension =
        path.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!_allowedExtensions.contains(extension)) {
      throw ValidationException(
        'Tipo de arquivo não permitido: .$extension. Permitidos: ${_allowedExtensions.join(", ")}',
      );
    }
  }

  static String _generateFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final basename = path.basename(originalPath);
    return '${timestamp}_$basename';
  }

  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg'; // fallback
    }
  }

  static StorageException _handleFirebaseStorageException(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return StorageException(
          'Sem permissão para acessar o arquivo',
          code: 'unauthorized',
          originalError: e,
        );
      case 'canceled':
        return StorageException(
          'Upload cancelado',
          code: 'canceled',
          originalError: e,
        );
      case 'unknown':
        return StorageException(
          'Erro desconhecido no armazenamento',
          code: 'unknown',
          originalError: e,
        );
      case 'object-not-found':
        return StorageException(
          'Arquivo não encontrado',
          code: 'not_found',
          originalError: e,
        );
      case 'bucket-not-found':
        return StorageException(
          'Bucket de armazenamento não encontrado',
          code: 'bucket_not_found',
          originalError: e,
        );
      case 'project-not-found':
        return StorageException(
          'Projeto Firebase não encontrado',
          code: 'project_not_found',
          originalError: e,
        );
      case 'quota-exceeded':
        return StorageException(
          'Cota de armazenamento excedida',
          code: 'quota_exceeded',
          originalError: e,
        );
      case 'unauthenticated':
        return StorageException(
          'Usuário não autenticado',
          code: 'unauthenticated',
          originalError: e,
        );
      case 'retry-limit-exceeded':
        return StorageException(
          'Limite de tentativas excedido',
          code: 'retry_limit_exceeded',
          originalError: e,
        );
      case 'invalid-checksum':
        return StorageException(
          'Checksum do arquivo inválido',
          code: 'invalid_checksum',
          originalError: e,
        );
      case 'canceled':
        return StorageException(
          'Operação cancelada',
          code: 'canceled',
          originalError: e,
        );
      default:
        return StorageException(
          'Erro no Firebase Storage: ${e.message ?? e.code}',
          code: e.code,
          originalError: e,
        );
    }
  }
}
