import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final permissionStatusProvider = FutureProvider<Map<PermissionType, bool>>((ref) async {
  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.checkAllPermissions();
});

final requestPermissionsProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.requestAllPermissions();
});
