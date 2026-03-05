import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _key = 'nourisha_device_id';

  /// Returns a stable device ID. Generates a UUID-like string on first call,
  /// then returns the same value forever from SharedPreferences.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if device ID already exists
    String? deviceId = prefs.getString(_key);
    
    if (deviceId == null || deviceId.isEmpty) {
      // Generate new device ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = math.Random().nextInt(999999).toString().padLeft(6, '0');
      deviceId = 'dev_${timestamp}_$random';
      
      // Save to SharedPreferences
      await prefs.setString(_key, deviceId);
    }
    
    return deviceId;
  }
}
