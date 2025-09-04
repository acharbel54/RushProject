import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const double _defaultLatitude = 48.8566;
  static const double _defaultLongitude = 2.3522; // Paris par défaut

  /// Vérifie et demande les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      // Vérifier le statut actuel de la permission
      PermissionStatus permission = await Permission.location.status;
      
      if (permission.isDenied) {
        // Demander la permission
        permission = await Permission.location.request();
      }
      
      if (permission.isPermanentlyDenied) {
        // Ouvrir les paramètres de l'application
        await openAppSettings();
        return false;
      }
      
      return permission.isGranted;
    } catch (e) {
      print('Erreur lors de la demande de permission: $e');
      return false;
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  static Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Le service de localisation est désactivé');
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Obtient la position par défaut (Paris)
  static Position getDefaultPosition() {
    return Position(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Convertit une adresse en coordonnées géographiques
  static Future<Position?> getPositionFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('Erreur lors du géocodage: $e');
      return null;
    }
  }

  /// Convertit des coordonnées en adresse
  static Future<String?> getAddressFromPosition(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return _formatAddress(placemark);
      }
      return null;
    } catch (e) {
      print('Erreur lors du géocodage inverse: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux points en kilomètres
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convertir en kilomètres
  }

  /// Formate une distance en texte lisible
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Vérifie si un point est dans un rayon donné
  static bool isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusInKm,
  ) {
    double distance = calculateDistance(
      centerLat,
      centerLng,
      pointLat,
      pointLng,
    );
    return distance <= radiusInKm;
  }

  /// Obtient les coordonnées d'une ville française
  static Position? getCityPosition(String cityName) {
    final cities = {
      'paris': Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      'lyon': Position(
        latitude: 45.7640,
        longitude: 4.8357,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      'marseille': Position(
        latitude: 43.2965,
        longitude: 5.3698,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      'toulouse': Position(
        latitude: 43.6047,
        longitude: 1.4442,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      'nice': Position(
        latitude: 43.7102,
        longitude: 7.2620,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    };
    
    return cities[cityName.toLowerCase()];
  }

  /// Formate une adresse à partir d'un Placemark
  static String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      addressParts.add(placemark.postalCode!);
    }
    
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }

  /// Obtient une position sûre (actuelle ou par défaut)
  static Future<Position> getSafePosition() async {
    final currentPosition = await getCurrentPosition();
    return currentPosition ?? getDefaultPosition();
  }

  /// Vérifie si les services de localisation sont disponibles
  static Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied &&
             permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }

  /// Ouvre les paramètres de localisation du système
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      print('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }

  /// Surveille les changements de position
  static Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Mise à jour tous les 100 mètres
    );
    
    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}