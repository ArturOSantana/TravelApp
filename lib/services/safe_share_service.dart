import 'package:share_plus/share_plus.dart';

/// Serviço seguro de compartilhamento que evita erros de sharePositionOrigin em iPads
class SafeShareService {
  /// Compartilha arquivos de forma segura sem usar sharePositionOrigin
  static Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
  }) async {
    try {
      // Força o compartilhamento sem sharePositionOrigin para evitar erros em iPads
      return await Share.shareXFiles(
        files,
        subject: subject,
        text: text,
        // Explicitamente não passa sharePositionOrigin
      );
    } catch (e) {
      // Se falhar, tenta novamente sem parâmetros opcionais
      return await Share.shareXFiles(files);
    }
  }

  /// Compartilha texto de forma segura
  static Future<ShareResult> share(
    String text, {
    String? subject,
  }) async {
    try {
      return await Share.share(
        text,
        subject: subject,
        // Explicitamente não passa sharePositionOrigin
      );
    } catch (e) {
      // Se falhar, tenta novamente apenas com o texto
      return await Share.share(text);
    }
  }
}
