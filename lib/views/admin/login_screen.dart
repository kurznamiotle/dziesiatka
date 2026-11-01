import 'package:dziesiatka/services/admin_auth_service.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:flutter/material.dart';

const _formWidth = 360.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.adminService,
    required this.onSignedIn,
  });

  final AdminAuthService authService;
  final AdminService adminService;
  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    String? error;
    var isAdmin = false;
    try {
      final isAccepted = await widget.authService.signIn(
        _email.text.trim(),
        _password.text,
      );
      if (isAccepted) {
        isAdmin = await widget.adminService.isAdmin();
        if (!isAdmin) {
          widget.authService.signOut();
          error = 'To konto nie ma dostępu do panelu.';
        }
      } else {
        error = 'Niepoprawny adres e-mail lub hasło.';
      }
    } catch (_) {
      widget.authService.signOut();
      error = 'Nie udało się połączyć. Spróbuj ponownie.';
    }
    if (!mounted) return;

    setState(() {
      _isBusy = false;
      _error = error;
    });
    if (isAdmin) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _formWidth),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Text(
                    'Dziesiątka: panel',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Adres e-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _signIn(),
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null)
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  FilledButton(
                    onPressed: _isBusy ? null : _signIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_isBusy ? 'Logowanie...' : 'Zaloguj się'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
