import 'package:dziesiatka/services/admin_auth_service.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/views/admin/admin_shell.dart';
import 'package:dziesiatka/views/admin/login_screen.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key, this.authService, this.adminService});

  final AdminAuthService? authService;
  final AdminService? adminService;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final _auth = widget.authService ?? AdminAuthService.fromConfig();
  late final _admin = widget.adminService ?? AdminService(_auth);

  void _signOut() {
    setState(_auth.signOut);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dziesiątka: panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _auth.isSignedIn
          ? AdminShell(adminService: _admin, onSignOut: _signOut)
          : LoginScreen(
              authService: _auth,
              adminService: _admin,
              onSignedIn: () => setState(() {}),
            ),
    );
  }
}
