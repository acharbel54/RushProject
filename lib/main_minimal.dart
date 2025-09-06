import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/simple_auth_provider.dart';
import 'core/providers/reservation_provider.dart';
import 'features/donations/providers/donation_provider.dart';
import 'features/reservations/screens/reservations_screen.dart';

void main() {
  runApp(const FoodLinkMinimalApp());
}

class FoodLinkMinimalApp extends StatelessWidget {
  const FoodLinkMinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SimpleAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ReservationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => DonationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FoodLink - Minimal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ReservationsScreen(),
      ),
    );
  }
}