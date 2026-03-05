import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_location.dart';

/// Service for handling location detection, geocoding, and persistence
class LocationService {
  static const String _savedLocationKey = 'saved_delivery_location';

  // Hardcoded serviceable zones
  static final List<String> _serviceablePincodes = [
    '600001', '600002', '600003', '600004', '600005', '600006', '600007',
    '600008', '600009', '600010', '600011', '600012', '600013', '600014',
    '600015', '600016', '600017', '600018', '600020', '600021', '600024',
    '600028', '600029', '600030', '600031', '600032', '600033', '600034',
    '600035', '600036', '600037', '600038', '600039', '600040', '600041',
    '110001', '110002', '110003', '110005', '110006', '110007', '110008',
    '110009', '110010', '110011', '110012', '110013', '110014', '110015',
    '400001', '400002', '400003', '400004', '400005', '400006', '400007',
    '400008', '400009', '400010', '400011', '400012', '400013', '400014',
    '560001', '560002', '560003', '560004', '560005', '560006', '560007',
    '560008', '560009', '560010', '560011', '560012', '560013', '560014',
  ];

  static final List<String> _serviceableCities = [
    'chennai',
    'delhi',
    'new delhi',
    'mumbai',
    'bangalore',
    'bengaluru',
    'hyderabad',
    'pune',
    'kolkata',
    'ahmedabad',
  ];

  /// Get saved location from SharedPreferences
  Future<DeliveryLocation?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_savedLocationKey);
      if (jsonString != null) {
        return DeliveryLocation.fromJsonString(jsonString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save location to SharedPreferences
  Future<bool> saveLocation(DeliveryLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedLocationKey, location.toJsonString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear saved location
  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedLocationKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check and request location permission
  Future<LocationPermission> checkAndRequestPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Get current GPS position
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Convert coordinates to DeliveryLocation with serviceability check
  Future<DeliveryLocation> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('No address found for coordinates');
      }

      final placemark = placemarks.first;
      final city = placemark.locality ?? '';
      final pincode = placemark.postalCode ?? '';
      final fullAddress = _buildFullAddress(placemark);
      final isServiceable = _checkServiceability(city, pincode);

      return DeliveryLocation(
        latitude: latitude,
        longitude: longitude,
        fullAddress: fullAddress,
        city: city,
        pincode: pincode,
        isServiceable: isServiceable,
      );
    } catch (e) {
      throw Exception('Failed to get location details: $e');
    }
  }

  /// Forward geocode address string to coordinates, then get full location
  Future<DeliveryLocation> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Address not found');
      }

      final location = locations.first;
      return await getLocationFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      throw Exception('Failed to find address: $e');
    }
  }

  /// Build human-readable full address from placemark
  String _buildFullAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.subThoroughfare != null &&
        placemark.subThoroughfare!.isNotEmpty) {
      parts.add(placemark.subThoroughfare!);
    }

    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      parts.add(placemark.thoroughfare!);
    }

    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }

    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      parts.add(placemark.postalCode!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }

    return parts.join(', ');
  }

  /// Check if location is serviceable based on city or pincode
  bool _checkServiceability(String city, String pincode) {
    final cityLower = city.toLowerCase().trim();
    final pincodeTrimmed = pincode.trim();

    // Check if city is serviceable
    if (_serviceableCities.contains(cityLower)) {
      return true;
    }

    // Check if pincode is serviceable
    if (_serviceablePincodes.contains(pincodeTrimmed)) {
      return true;
    }

    return false;
  }
}
