import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/delivery_location.dart';
import '../services/location_service.dart';
import 'menu_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _showManualSearch = false;
  String _statusMessage = '';
  String _errorMessage = '';
  DeliveryLocation? _detectedLocation;

  @override
  void initState() {
    super.initState();
    // Auto-attempt GPS detection on screen load
    _detectLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Auto-detect location using GPS
  Future<void> _detectLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Detecting your location...';
      _detectedLocation = null;
      _showManualSearch = false;
    });

    try {
      // Check and request permission
      final permission = await _locationService.checkAndRequestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _showManualSearch = true;
          _errorMessage = permission == LocationPermission.deniedForever
              ? 'Location permission permanently denied. Please enable in settings or enter address manually.'
              : 'Location permission denied. Please enter address manually.';
        });
        return;
      }

      // Get current position
      setState(() {
        _statusMessage = 'Getting GPS coordinates...';
      });
      final position = await _locationService.getCurrentPosition();

      // Reverse geocode
      setState(() {
        _statusMessage = 'Finding your address...';
      });
      final location = await _locationService.getLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _isLoading = false;
        _detectedLocation = location;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showManualSearch = true;
        _errorMessage = 'Failed to detect location: ${e.toString()}';
      });
    }
  }

  /// Search address manually
  Future<void> _searchAddress() async {
    final address = _searchController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Searching for address...';
      _detectedLocation = null;
    });

    try {
      final location = await _locationService.getLocationFromAddress(address);

      setState(() {
        _isLoading = false;
        _detectedLocation = location;
        _showManualSearch = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Address not found. Please try a different address.';
      });
    }
  }

  /// Confirm and save location, then navigate to menu
  Future<void> _confirmLocation() async {
    if (_detectedLocation == null) return;

    if (!_detectedLocation!.isServiceable) {
      _showNotServiceableDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Saving location...';
    });

    final saved = await _locationService.saveLocation(_detectedLocation!);

    if (saved) {
      _navigateToMenu();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save location. Please try again.';
      });
    }
  }

  /// Navigate to menu screen
  void _navigateToMenu() {
    if (_detectedLocation == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MenuScreen(location: _detectedLocation!),
      ),
    );
  }

  /// Show dialog when location is not serviceable
  void _showNotServiceableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Serviceable'),
        content: const Text(
          'Sorry, we do not deliver to this location yet. '
          'We are currently available in select cities and areas. '
          'Please try a different address.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showManualSearch = true;
                _detectedLocation = null;
              });
            },
            child: const Text('Try Different Address'),
          ),
        ],
      ),
    );
  }

  /// Open device settings for location permission
  Future<void> _openSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Detected location card
              if (_detectedLocation != null && !_showManualSearch)
                _LocationCard(
                  location: _detectedLocation!,
                  isLoading: _isLoading,
                  onConfirm: _confirmLocation,
                  onDetectAgain: _detectLocation,
                  onEnterManually: () {
                    setState(() {
                      _showManualSearch = true;
                      _detectedLocation = null;
                    });
                  },
                ),

              // Manual search widget
              if (_showManualSearch)
                _ManualSearchWidget(
                  controller: _searchController,
                  isLoading: _isLoading,
                  onSearch: _searchAddress,
                  onTryGPS: _detectLocation,
                  onOpenSettings: _openSettings,
                  showOpenSettings: _errorMessage.contains('permanently denied'),
                ),

              // Initial loading state
              if (_isLoading && _detectedLocation == null && !_showManualSearch)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display detected location with serviceability badge
class _LocationCard extends StatelessWidget {
  final DeliveryLocation location;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onDetectAgain;
  final VoidCallback onEnterManually;

  const _LocationCard({
    required this.location,
    required this.isLoading,
    required this.onConfirm,
    required this.onDetectAgain,
    required this.onEnterManually,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFF2563EB),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Detected Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            location.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Serviceability badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: location.isServiceable ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: location.isServiceable ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  location.isServiceable ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: location.isServiceable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  location.isServiceable ? 'Serviceable' : 'Not Serviceable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: location.isServiceable ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Buttons
          if (location.isServiceable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Deliver Here',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onDetectAgain,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Detect Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onEnterManually,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Enter Manually'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for manual address search
class _ManualSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onTryGPS;
  final VoidCallback onOpenSettings;
  final bool showOpenSettings;

  const _ManualSearchWidget({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onTryGPS,
    required this.onOpenSettings,
    required this.showOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Address Manually',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your address',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: 2,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Search Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onTryGPS,
              icon: const Icon(Icons.my_location, size: 20),
              label: const Text('Try GPS Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (showOpenSettings) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onOpenSettings,
                icon: const Icon(Icons.settings, size: 20),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
