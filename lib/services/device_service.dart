import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing stable device identification
///
/// Generates a unique device ID on first use and persists it
/// for consistent device tracking across app sessions.
class DeviceService {
  static const String _key = 'nourisha_device_id';

  /// Returns a stable device ID. Generates a UUID-like string on first call,
  /// then returns the same value forever from SharedPreferences.
  ///
  /// Format: dev_{timestamp}_{random6digits}
  /// Example: dev_1772622322123_456789
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if device ID already exists
    String? deviceId = prefs.getString(_key);
    
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }
    
    // Generate new device ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999).toString().padLeft(6, '0');
    deviceId = 'dev_${timestamp}_$random';
    
    // Save to SharedPreferences
    await prefs.setString(_key, deviceId);
    
    return deviceId;
  }
}
