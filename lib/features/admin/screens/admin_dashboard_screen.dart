import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/models/reservation_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin-dashboard';
  
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    
    // Vérifier si l'utilisateur est admin
    if (authProvider.currentUser?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Administrator access required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.food_bank), text: 'Donations'),
            Tab(icon: Icon(Icons.bookmark), text: 'Reservations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildDonationsTab(),
          _buildReservationsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques générales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Users',
                  icon: Icons.people,
                  color: Colors.blue,
                  stream: _firestore.collection('users').snapshots(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Donations',
                  icon: Icons.food_bank,
                  color: Colors.green,
                  stream: _firestore
                      .collection('donations')
                      .where('status', isEqualTo: 'available')
                      .snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Reservations',
                  icon: Icons.bookmark,
                  color: Colors.orange,
                  stream: _firestore.collection('reservations').snapshots(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Dons expirés',
                  icon: Icons.warning,
                  color: Colors.red,
                  stream: _firestore
                      .collection('donations')
                      .where('status', isEqualTo: 'expired')
                      .snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.data!.docs.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cleaning_services, color: Colors.blue),
          title: const Text('Clean Expired Donations'),
          subtitle: const Text('Delete donations expired for more than 7 days'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _cleanExpiredDonations,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications, color: Colors.orange),
          title: const Text('Send global notification'),
          subtitle: const Text('Send a notification to all users'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showGlobalNotificationDialog,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.analytics, color: Colors.green),
          title: const Text('Generate report'),
          subtitle: const Text('Export usage statistics'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _generateReport,
        ),
      ],
    );
  }
  
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading users'),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final users = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final user = UserModel.fromDocument(users[index]);
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getUserTypeColor(user.role),
                child: Text(
                  user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.displayName ?? 'Utilisateur'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  Text(
                    _getUserTypeText(user.role),
                    style: TextStyle(
                      color: _getUserTypeColor(user.role),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View details'),
                  ),
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Text('Suspendre'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    _showUserDetails(user);
                  } else if (value == 'suspend') {
                    _suspendUser(user.id);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildDonationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('donations').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading donations'),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final donations = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donationData = donations[index].data() as Map<String, dynamic>;
            final donation = DonationModel.fromJson(donationData);
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getDonationStatusColor(donation.status),
                  child: Icon(
                    Icons.food_bank,
                    color: Colors.white,
                  ),
                ),
                title: Text(donation.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${donation.quantity}'),
                    Text(
                      'Status: ${_getDonationStatusText(donation.status)}',
                      style: TextStyle(
                        color: _getDonationStatusColor(donation.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showDonationDetails(donation);
                    } else if (value == 'delete') {
                      _deleteDonation(donation.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildReservationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reservations').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading reservations'),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final reservations = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservationData = reservations[index].data() as Map<String, dynamic>;
            final reservation = ReservationModel.fromDocument(reservations[index]);
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getReservationStatusColor(reservation.status),
                  child: Icon(
                    Icons.bookmark,
                    color: Colors.white,
                  ),
                ),
                title: Text('Reservation ${reservation.id.substring(0, 8)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Don: ${reservation.donationId.substring(0, 8)}'),
                    Text(
                      'Status: ${_getReservationStatusText(reservation.status)}',
                      style: TextStyle(
                        color: _getReservationStatusColor(reservation.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View details'),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showReservationDetails(reservation);
                    } else if (value == 'cancel') {
                      _cancelReservation(reservation.id);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Méthodes utilitaires
  Color _getUserTypeColor(UserRole userType) {
    switch (userType) {
      case UserRole.donateur:
        return Colors.green;
      case UserRole.beneficiaire:
        return Colors.blue;
      case UserRole.admin:
        return Colors.purple;
    }
  }
  
  String _getUserTypeText(UserRole userType) {
    switch (userType) {
      case UserRole.donateur:
        return 'Donor';
      case UserRole.beneficiaire:
        return 'Beneficiary';
      case UserRole.admin:
        return 'Administrator';
    }
  }
  
  Color _getDonationStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.disponible:
        return Colors.green;
      case DonationStatus.reserve:
        return Colors.orange;
      case DonationStatus.recupere:
        return Colors.blue;
      case DonationStatus.expire:
        return Colors.red;
    }
  }
  
  String _getDonationStatusText(DonationStatus status) {
    switch (status) {
      case DonationStatus.disponible:
        return 'Available';
      case DonationStatus.reserve:
        return 'Reserved';
      case DonationStatus.recupere:
        return 'Completed';
      case DonationStatus.expire:
        return 'Expired';
    }
  }
  
  Color _getReservationStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }
  
  String _getReservationStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  // Actions
  void _cleanExpiredDonations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Expired Donations'),
        content: const Text('Are you sure you want to delete all donations expired for more than 7 days?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCleanup();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _performCleanup() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final querySnapshot = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'expired')
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${querySnapshot.docs.length} dons expirés supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during cleanup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showGlobalNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendGlobalNotification(titleController.text, messageController.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
  
  void _sendGlobalNotification(String title, String message) async {
    if (title.isEmpty || message.isEmpty) return;
    
    try {
      // Récupérer tous les utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'body': message,
          'type': 'systemMessage',
          'data': {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification envoyée à ${usersSnapshot.docs.length} utilisateurs'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during sending'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de rapport en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Details of ${user.displayName ?? user.email}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Type: ${_getUserTypeText(user.role)}'),
            Text('Phone: ${user.phoneNumber}'),
             Text('Address: ${user.address}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _suspendUser(String userId) {
    // TODO: Implémenter la suspension d'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de suspension en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _showDonationDetails(DonationModel donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${donation.description}'),
            Text('Quantity: ${donation.quantity}'),
            Text('Status: ${_getDonationStatusText(donation.status)}'),
            Text('Created on: ${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _deleteDonation(String donationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Donation'),
      content: const Text('Are you sure you want to delete this donation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('donations').doc(donationId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Don supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error during deletion'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showReservationDetails(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réservation ${reservation.id.substring(0, 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donation ID: ${reservation.donationId}'),
            Text('Beneficiary ID: ${reservation.beneficiaryId}'),
            Text('Status: ${_getReservationStatusText(reservation.status)}'),
           Text('Created on: ${reservation.createdAt.day}/${reservation.createdAt.month}/${reservation.createdAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _cancelReservation(String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
      content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('reservations').doc(reservationId).update({
                  'status': 'cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservation cancelled'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error during cancellation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }
}