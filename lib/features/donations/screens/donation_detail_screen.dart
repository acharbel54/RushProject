import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/donation_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../services/local_image_service.dart';

class DonationDetailScreen extends StatefulWidget {
  static const String routeName = '/donation-detail';
  
  final String donationId;
  
  const DonationDetailScreen({
    Key? key,
    required this.donationId,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  DonationModel? donation;
  SimpleUser? donorInfo;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDonation();
  }

  Future<void> _loadDonation() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final loadedDonation = await donationProvider.getDonationById(widget.donationId);
      
      // Load donor information
      SimpleUser? loadedDonorInfo;
      if (loadedDonation != null && loadedDonation.donorId.isNotEmpty) {
        loadedDonorInfo = await authProvider.getUserById(loadedDonation.donorId);
      }
      
      if (mounted) {
        setState(() {
          donation = loadedDonation;
          donorInfo = loadedDonorInfo;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Donation Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const LoadingOverlay(
          isLoading: true,
          child: SizedBox.expand(),
        ),
      );
    }

    if (error != null || donation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Donation Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Donation not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'This donation no longer exists or has been deleted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du don
            Text(
              donation!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Quantity section
            _buildInfoSection(
              Icons.inventory_2_outlined,
              'Quantity',
              donation!.quantity,
              const Color(0xFFFFA726), // Orange
            ),
            const SizedBox(height: 16),
            
            // Section Date d'expiration
            _buildInfoSection(
              Icons.calendar_today,
              'Expiration Date',
              DateFormat('dd MMMM yyyy', 'fr_FR').format(donation!.expirationDate),
              const Color(0xFFFFA726), // Orange
            ),
            const SizedBox(height: 16),
            
            // Section Instructions de récupération
            _buildInfoSection(
              Icons.info_outline,
              'Pickup Instructions',
              donation!.description.isNotEmpty 
                  ? donation!.description 
                  : 'Present yourself at the back of the restaurant between 2pm and 4pm. Ring the service door.',
              const Color(0xFFFFA726), // Orange
            ),
            const SizedBox(height: 16),
            
            // Donor contact section
            _buildInfoSection(
              Icons.phone,
              'Donor Contact',
              donorInfo?.displayName ?? 'Jean Dupont - 06 12 34 56 78',
              const Color(0xFFFFA726), // Orange
            ),
            const SizedBox(height: 16),
            
            // Section Localisation
            _buildInfoSection(
              Icons.location_on,
              'Location',
              donation!.address,
              const Color(0xFFFFA726), // Orange
            ),
            const SizedBox(height: 24),
            
            // Image du don
            if (donation!.imageUrls.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildDonationImage(),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No image available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationImage() {
     final imageUrl = donation!.imageUrls.first;
     
     // Vérifier si c'est un fichier local ou une URL
     if (imageUrl.startsWith('assets/')) {
      // Image locale dans le dossier assets - utiliser FutureBuilder pour obtenir le chemin absolu
      return FutureBuilder<String>(
        future: LocalImageService.getAbsolutePath(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image not available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
     } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Fichier local
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Image non disponible',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _openMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(donation!.address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}