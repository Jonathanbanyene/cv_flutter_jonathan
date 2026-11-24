import 'package:flutter/material.dart';

import 'api.dart';
import 'main.dart'; // pour HomeShell

// ------------------------------------------------------------
//  PAGE 1 : CONNEXION RÉELLE (via l'API) + création de compte
// ------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  bool _creation = false; // false = connexion, true = création de compte

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_creation) {
        await Api.register(_emailCtrl.text.trim(), _pwdCtrl.text);
        if (!mounted) return;
        toast(context, 'Compte créé. Tu peux maintenant te connecter.');
        setState(() => _creation = false);
      } else {
        await Api.login(_emailCtrl.text.trim(), _pwdCtrl.text);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle, size: 90, color: color),
                  const SizedBox(height: 12),
                  Text(
                    _creation ? 'Créer un compte' : 'Connexion',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant (e-mail)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Entre ton e-mail';
                      if (!t.contains('@')) return 'E-mail invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwdCtrl,
                    obscureText: _hidePassword, // texte masqué
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Entre ton mot de passe';
                      if (_creation && v.length < 6) {
                        return '6 caractères minimum';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_creation ? 'Créer le compte' : 'Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _creation = !_creation),
                    child: Text(_creation
                        ? 'J\'ai déjà un compte : me connecter'
                        : 'Pas de compte ? En créer un'),
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
