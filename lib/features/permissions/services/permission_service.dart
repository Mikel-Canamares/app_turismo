import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

enum PermissionType {
  location,
  microphone,
  speech,
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Solicita todos los permisos necesarios para la aplicación
  Future<bool> requestAllPermissions() async {
    try {
      print('🔐 Solicitando permisos...');
      
      // Solicitar solo permiso de ubicación cuando la app está en uso
      final locationWhenInUse = await Permission.locationWhenInUse.request();
      print('📍 Permiso ubicación cuando en uso: $locationWhenInUse');
      
      // Solicitar permiso de micrófono
      final microphone = await Permission.microphone.request();
      print('🎤 Permiso micrófono: $microphone');
      
      // Solicitar permiso de reconocimiento de voz si está disponible
      final speech = await Permission.speech.request();
      print('🗣️ Permiso reconocimiento de voz: $speech');
      
      final allGranted = locationWhenInUse.isGranted && microphone.isGranted;
      
      print('✅ Permisos críticos concedidos: $allGranted');
      return allGranted;
      
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Solicita un permiso específico
  Future<bool> requestPermission(PermissionType type) async {
    Permission permission;
    
    switch (type) {
      case PermissionType.location:
        permission = Permission.locationWhenInUse;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
      case PermissionType.speech:
        permission = Permission.speech;
        break;
    }

    final status = await permission.request();
    print('🔐 Permiso $type solicitado: $status');
    return status == PermissionStatus.granted;
  }

  /// Verifica el estado de un permiso específico
  Future<bool> checkPermission(PermissionType type) async {
    Permission permission;
    
    switch (type) {
      case PermissionType.location:
        permission = Permission.locationWhenInUse;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
      case PermissionType.speech:
        permission = Permission.speech;
        break;
    }

    final status = await permission.status;
    return status == PermissionStatus.granted;
  }

  /// Verifica el estado actual de todos los permisos
  Future<Map<String, PermissionStatus>> checkPermissionsStatus() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      final microphoneStatus = await Permission.microphone.status;
      final speechStatus = await Permission.speech.status;
      
      print('📊 Estado de permisos:');
      print('  📍 Ubicación: $locationStatus');
      print('  🎤 Micrófono: $microphoneStatus');
      print('  🗣️ Reconocimiento de voz: $speechStatus');
      
      return {
        'location': locationStatus,
        'microphone': microphoneStatus,
        'speech': speechStatus,
      };
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return {
        'location': PermissionStatus.denied,
        'microphone': PermissionStatus.denied,
        'speech': PermissionStatus.denied,
      };
    }
  }

  /// Verifica si todos los permisos críticos están concedidos
  Future<bool> areAllPermissionsGranted() async {
    final status = await checkPermissionsStatus();
    return status['location']?.isGranted == true && 
           status['microphone']?.isGranted == true;
  }

  /// Verifica el estado de todos los permisos (versión legacy)
  Future<Map<PermissionType, bool>> checkAllPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final microphoneStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;
    
    return {
      PermissionType.location: locationStatus == PermissionStatus.granted,
      PermissionType.microphone: microphoneStatus == PermissionStatus.granted,
      PermissionType.speech: speechStatus == PermissionStatus.granted,
    };
  }

  /// Abre la configuración de la aplicación si los permisos fueron denegados
  Future<void> openSettings() async {
    try {
      await openAppSettings();
      print('📱 Abriendo configuración de la aplicación');
    } catch (e) {
      print('❌ Error abriendo configuración: $e');
    }
  }

  /// Muestra un diálogo explicativo sobre los permisos requeridos
  Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔐 Permisos Requeridos'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para funcionar correctamente, Turismo AI necesita:'),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('📍 '),
                  Expanded(child: Text('Ubicación: Para encontrar lugares de interés cercanos')),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text('🎤 '),
                  Expanded(child: Text('Micrófono: Para escuchar tus preguntas por voz')),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text('🗣️ '),
                  Expanded(child: Text('Reconocimiento de voz: Para convertir audio en texto')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Conceder Permisos'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}