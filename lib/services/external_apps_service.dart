import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/activity.dart';

class ExternalAppsService {
  //google maps
  static Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      final Uri mapsUrl;

      if (Platform.isIOS) {
        mapsUrl = Uri.parse(
          'maps://?q=${label ?? 'Local'}&ll=$latitude,$longitude',
        );

        if (!await canLaunchUrl(mapsUrl)) {
          final googleMapsUrl = Uri.parse(
            'comgooglemaps://?q=$latitude,$longitude&label=${label ?? 'Local'}',
          );

          if (await canLaunchUrl(googleMapsUrl)) {
            return await launchUrl(googleMapsUrl);
          }

          final webUrl = Uri.parse(
            'https://maps.google.com/?q=$latitude,$longitude',
          );
          return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        mapsUrl = Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude(${label ?? 'Local'})',
        );

        if (!await canLaunchUrl(mapsUrl)) {
          final webUrl = Uri.parse(
            'https://maps.google.com/?q=$latitude,$longitude',
          );
          return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }

      return await launchUrl(mapsUrl);
    } catch (e) {
      print('Erro ao abrir Maps: $e');
      return false;
    }
  }

  static Future<bool> addToCalendar(Activity activity) async {
    try {
      final startDate = activity.time;
      final endDate =
          startDate.add(const Duration(hours: 1)); 

      final startStr = _formatDateForCalendar(startDate);
      final endStr = _formatDateForCalendar(endDate);

      final description = activity.location.isNotEmpty
          ? 'Local: ${activity.location}'
          : 'Atividade da viagem';

    
      final calendarUrl = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(activity.title)}'
        '&dates=$startStr/$endStr'
        '&details=${Uri.encodeComponent(description)}'
        '&location=${Uri.encodeComponent(activity.location)}'
        '&sf=true&output=xml',
      );

      return await launchUrl(
        calendarUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Erro ao adicionar ao Calendar: $e');
      return false;
    }
  }

  static String _formatDateForCalendar(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

 
  static Future<bool> openInWaze({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final wazeUrl = Uri.parse(
        'waze://?ll=$latitude,$longitude&navigate=yes',
      );

      if (await canLaunchUrl(wazeUrl)) {
        return await launchUrl(wazeUrl);
      }

      return await openInMaps(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('Erro ao abrir Waze: $e');
      return false;
    }
  }

  
  static Future<bool> shareLocation({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    try {
      final message = '$name\nhttps://maps.google.com/?q=$latitude,$longitude';
      final shareUrl = Uri.parse(
        'sms:?body=${Uri.encodeComponent(message)}',
      );

      return await launchUrl(shareUrl);
    } catch (e) {
      print('Erro ao compartilhar localização: $e');
      return false;
    }
  }
}

