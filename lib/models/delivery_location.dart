import 'dart:convert';

/// Model representing a delivery location with serviceability information
class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String city;
  final String pincode;
  final bool isServiceable;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.city,
    required this.pincode,
    required this.isServiceable,
  });

  /// Convert to JSON for SharedPreferences persistence
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'city': city,
      'pincode': pincode,
      'isServiceable': isServiceable,
    };
  }

  /// Create from JSON stored in SharedPreferences
  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String,
      pincode: json['pincode'] as String,
      isServiceable: json['isServiceable'] as bool,
    );
  }

  /// Convert to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory DeliveryLocation.fromJsonString(String jsonString) {
    return DeliveryLocation.fromJson(jsonDecode(jsonString));
  }

  @override
  String toString() {
    return 'DeliveryLocation(lat: $latitude, lng: $longitude, address: $fullAddress, city: $city, pincode: $pincode, serviceable: $isServiceable)';
  }
}
