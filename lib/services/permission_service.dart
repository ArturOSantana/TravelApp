import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço centralizado para gerenciar permissões do app
class PermissionService {
  /// Verifica e solicita permissão de localização
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final shouldOpenSettings = await _showLocationServiceDialog(context);
        if (shouldOpenSettings) {
          await Geolocator.openLocationSettings();
        }
        return false;
      }

      // Verifica permissões usando geolocator
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final shouldRequest = await _showPermissionRationaleDialog(context);
        if (!shouldRequest) {
          return false;
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedSnackbar(context);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final shouldOpenSettings =
            await _showPermissionDeniedForeverDialog(context);
        if (shouldOpenSettings) {
          await Geolocator.openAppSettings();
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Erro ao solicitar permissão de localização: $e');
      _showErrorSnackbar(context, 'Erro ao verificar permissões');
      return false;
    }
  }

  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Erro ao verificar permissão: $e');
      return false;
    }
  }

  static Future<bool> _showPermissionRationaleDialog(
      BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Permissão de Localização'),
                  ),
                ],
              ),
              content: const SingleChildScrollView(
                child: Text(
                  'Este app precisa acessar sua localização para:\n\n'
                  '• Sugerir destinos próximos\n'
                  '• Mostrar clima local\n'
                  '• Criar roteiros personalizados\n'
                  '• Funcionalidades de segurança\n\n'
                  'Sua privacidade é importante. A localização só é usada quando você está usando o app.',
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Agora Não'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Permitir'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Localização Desabilitada'),
                  ),
                ],
              ),
              content: const SingleChildScrollView(
                child: Text(
                  'O serviço de localização está desabilitado no seu dispositivo.\n\n'
                  'Para usar recursos baseados em localização, você precisa ativar o GPS nas configurações do dispositivo.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir Configurações'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> _showPermissionDeniedForeverDialog(
      BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Permissão Negada'),
                  ),
                ],
              ),
              content: const SingleChildScrollView(
                child: Text(
                  'A permissão de localização foi negada permanentemente.\n\n'
                  'Para usar recursos baseados em localização, você precisa habilitar a permissão manualmente nas configurações do app.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir Configurações'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static void _showPermissionDeniedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Permissão de localização negada. Alguns recursos podem não funcionar.'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
