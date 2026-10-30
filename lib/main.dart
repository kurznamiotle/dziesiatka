import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/phone_frame.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DziesiatkaApp());
}

class DziesiatkaApp extends StatelessWidget {
  const DziesiatkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dziesiątka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      // Above the navigator, so routes, dialogs and sheets stay in the frame.
      builder: (context, child) => PhoneFrame(child: child!),
      home: const HomeScreen(),
    );
  }
}
