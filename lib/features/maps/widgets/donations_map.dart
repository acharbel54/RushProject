import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/models/donation.dart';
import '../../../core/services/location_service.dart';
import '../../donations/providers/donation_provider.dart';
import '../../donations/screens/donation_detail_screen.dart';

class DonationsMap extends StatefulWidget {
  final List<Donation>? donations;
  final Function(Donation)? onDonationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialZoom;
  final bool showUserLocation;
  final double searchRadius; // en kilomètres

  const DonationsMap({
    Key? key,
    this.donations,
    this.onDonationSelected,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom = 12.0,
    this.showUserLocation = true,
    this.searchRadius = 10.0,
  }) : super(key: key);

  @override
  State<DonationsMap> createState() => _DonationsMapState();
}

class _DonationsMapState extends State<DonationsMap> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  
  // Couleurs pour les différents statuts de dons
  static final Map<DonationStatus, BitmapDescriptor> _markerColors = {
    DonationStatus.disponible: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    DonationStatus.reserve: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    DonationStatus.recupere: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    DonationStatus.expire: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtenir la position actuelle si demandée
      if (widget.showUserLocation) {
        _currentPosition = await LocationService.getCurrentPosition();
      }

      // Utiliser la position fournie ou la position actuelle ou la position par défaut
      if (_currentPosition == null) {
        if (widget.initialLatitude != null && widget.initialLongitude != null) {
          _currentPosition = Position(
            latitude: widget.initialLatitude!,
            longitude: widget.initialLongitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        } else {
          _currentPosition = LocationService.getDefaultPosition();
        }
      }

      // Charger les dons si non fournis
      List<Donation> donations = widget.donations ?? [];
      if (donations.isEmpty) {
        final donationProvider = Provider.of<DonationProvider>(context, listen: false);
        await donationProvider.fetchDonations();
        donations = donationProvider.donations;
      }

      // Filtrer les dons par rayon si une position est disponible
      if (_currentPosition != null && widget.searchRadius > 0) {
        donations = donations.where((donation) {
          if (donation.latitude == null || donation.longitude == null) {
            return false;
          }
          
          double distance = LocationService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            donation.latitude!,
            donation.longitude!,
          );
          
          return distance <= widget.searchRadius;
        }).toList();
      }

      // Créer les marqueurs
      await _createMarkers(donations);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement de la carte: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createMarkers(List<Donation> donations) async {
    Set<Marker> markers = {};

    // Ajouter le marqueur de position utilisateur
    if (widget.showUserLocation && _currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Vous êtes ici',
          ),
        ),
      );
    }

    // Ajouter les marqueurs de dons
    for (Donation donation in donations) {
      if (donation.latitude != null && donation.longitude != null) {
        final distance = _currentPosition != null
            ? LocationService.calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                donation.latitude!,
                donation.longitude!,
              )
            : null;

        markers.add(
          Marker(
            markerId: MarkerId(donation.id),
            position: LatLng(donation.latitude!, donation.longitude!),
            icon: _markerColors[donation.status] ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: donation.title,
              snippet: distance != null
                  ? '${LocationService.formatDistance(distance)} • ${donation.type.name}'
: donation.type.name,
            ),
            onTap: () => _onMarkerTapped(donation),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(Donation donation) {
    if (widget.onDonationSelected != null) {
      widget.onDonationSelected!(donation);
    } else {
      // Navigation par défaut vers les détails du don
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonationDetailScreen(donationId: donation.id),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  Future<void> _refreshMap() async {
    await _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshMap,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition?.latitude ?? LocationService.getDefaultPosition().latitude,
              _currentPosition?.longitude ?? LocationService.getDefaultPosition().longitude,
            ),
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: false, // Nous utilisons notre propre bouton
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: true,
        ),
        
        // Bouton pour aller à la position actuelle
        if (widget.showUserLocation && _currentPosition != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        
        // Bouton de rafraîchissement
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _refreshMap,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.refresh,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        
        // Légende des couleurs
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Légende',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem(Colors.green, 'Disponible'),
                _buildLegendItem(Colors.orange, 'Réservé'),
                _buildLegendItem(Colors.blue, 'Terminé'),
                _buildLegendItem(Colors.red, 'Expiré'),
                if (widget.showUserLocation)
                  _buildLegendItem(Colors.blue, 'Ma position'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}