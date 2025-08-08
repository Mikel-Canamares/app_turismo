import 'package:permission_handler/permission_handler.dart';

enum PermissionType {
  location,
  microphone,
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestPermission(PermissionType type) async {
    Permission permission;
    
    switch (type) {
      case PermissionType.location:
        permission = Permission.location;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
    }

    final status = await permission.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> checkPermission(PermissionType type) async {
    Permission permission;
    
    switch (type) {
      case PermissionType.location:
        permission = Permission.location;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
    }

    final status = await permission.status;
    return status == PermissionStatus.granted;
  }

  Future<bool> requestAllPermissions() async {
    final Map<Permission, PermissionStatus> permissions = 
        await [Permission.location, Permission.microphone].request();
    
    final locationGranted = permissions[Permission.location] == PermissionStatus.granted;
    final microphoneGranted = permissions[Permission.microphone] == PermissionStatus.granted;
    
    return locationGranted && microphoneGranted;
  }

  Future<Map<PermissionType, bool>> checkAllPermissions() async {
    final locationStatus = await Permission.location.status;
    final microphoneStatus = await Permission.microphone.status;
    
    return {
      PermissionType.location: locationStatus == PermissionStatus.granted,
      PermissionType.microphone: microphoneStatus == PermissionStatus.granted,
    };
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
