import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
//  TP Flutter : application CV
//  Connexion de démonstration : jonathan 1234
// ============================================================

void main() => runApp(const CvApp());

class CvApp extends StatelessWidget {
  const CvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon CV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ------------------------------------------------------------
//  PAGE 1 : CONNEXION
// ------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _hidePassword = true;

  // À MODIFIER si tu veux d'autres identifiants
  static const _validId = 'jonathan';
  static const _validPwd = '1234';

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    if (_idCtrl.text.trim() == _validId && _pwdCtrl.text == _validPwd) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant ou mot de passe incorrect')),
      );
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
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Entre ton identifiant'
                        : null,
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Entre ton mot de passe'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _login,
                      child: const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Démo : jonathan / 1234',
                    style: TextStyle(color: Colors.grey.shade600),
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

// ------------------------------------------------------------
//  NAVIGATION (barre en bas) entre les 3 pages
// ------------------------------------------------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [CvPage(), FamillePage(), ContactPage()];
  final List<String> _titles = const ['Accueil : mon CV', 'Ma famille', 'Contact'];

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.family_restroom), label: 'Famille'),
          NavigationDestination(
              icon: Icon(Icons.contact_phone), label: 'Contact'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
//  WIDGETS RÉUTILISABLES
// ------------------------------------------------------------

/// Photo ronde. Si l'image est introuvable, une icône s'affiche.
class Photo extends StatelessWidget {
  final String asset;
  final double size;

  const Photo({super.key, required this.asset, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade300,
          child: Icon(Icons.person, size: size * 0.6, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Carte avec un titre et une icône.
class Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
            
Widget cvItem(String title, String subtitle,
[ IconData icon = Icons.check_circle_outline]) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
  );
}

Widget chips(List<String> items) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: items.map((e) => Chip(label: Text(e))).toList(),
  );
}

// ------------------------------------------------------------
//  PAGE 2 : ACCUEIL (CV)
// ------------------------------------------------------------
class CvPage extends StatelessWidget {
  const CvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- En-tête : photo, nom, titre ---
        Center(
          child: Column(
            children: [
              const Photo(asset: 'assets/images/moi.jpg', size: 120),
              const SizedBox(height: 12),
              Text(
                'Banyene Wetemwami Jonathan', 
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Étudiant en Sciences informatiques\nRéseaux et Télécommunications',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // --- Formation ---
        Section(
          title: 'Formation',
          icon: Icons.school,
          children: [
            cvItem(
              'Licence 4 en Sciences informatiques',
              'Option Réseaux et Télécommunications, Goma (RDC)',
              Icons.workspace_premium,
            ),
            cvItem(
              'Mon stage',
              'Description du stage',
              Icons.work,
            ),
          ],
        ),

        // --- Expériences ---
        Section(
          title: 'Expériences',
          icon: Icons.work,
          children: [
            cvItem(
              'Installation Wi-Fi ZONE',
              'Routeurs en mode point d\'accès dans une maison',
              Icons.router,
            ),
            cvItem(
              'Portfolio web',
              'HTML / CSS, publié avec GitHub Pages',
              Icons.language,
            ),
          ],
        ),

        // --- Compétences techniques ---
        Section(
          title: 'Compétences techniques',
          icon: Icons.build,
          children: [
            chips(['Cisco Packet Tracer', 'HTML / CSS', 'django', 'python']),
          ],
        ),

        // --- Compétences linguistiques ---
        Section(
          title: 'Langues',
          icon: Icons.translate,
          children: [
            chips(['Français']),
            chips(['Anglais']),
            chips(['Swahili']),
          ],
        ),

        // --- Centres d'intérêt ---
        Section(
          title: 'Centres d\'intérêt',
          icon: Icons.favorite,
          children: [
            chips(['Réseaux', 'Cybersécurité', 'Développement web']),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
//  PAGE 3 : FAMILLE
// ------------------------------------------------------------
class FamilyMember {
  final String name;
  final String relation;
  final String job;
  final String photo;

  const FamilyMember(this.name, this.relation, this.job, this.photo);
}

const List<FamilyMember> familyMembers = [
  FamilyMember('Wetemwami', 'Père', 'Mulitaire', 'assets/images/pere.jpg'),
  FamilyMember('Catherine', 'Mère', 'Nutritioniste', 'assets/images/mere.jpg'),
  FamilyMember('MOIse', 'Frère', 'Enseignant', 'assets/images/frere.jpg'),
  FamilyMember('SAFI', 'Sœur', 'Commercante', 'assets/images/soeur.jpg'),
];

class FamillePage extends StatelessWidget {
  const FamillePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: familyMembers.length,
      itemBuilder: (context, i) {
        final m = familyMembers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Photo(asset: m.photo, size: 60),
            title: Text(
              m.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${m.relation}\n${m.job}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
//  PAGE 4 : CONTACT (cliquable : appel, e-mail, liens)
// ------------------------------------------------------------
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) _error(context);
    } catch (_) {
      if (context.mounted) _error(context);
    }
  }

  void _error(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir ce lien')),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String value,
      {String? url}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
        trailing: url == null ? null : const Icon(Icons.open_in_new),
        onTap: url == null ? null : () => _open(context, url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile(context, Icons.phone, 'Téléphone', '+243 83 57 42 820',
            url: 'tel:+243835742820'),
        _tile(context, Icons.email, 'E-mail', 'djobanyene@gmail.com',
            url: 'mailto:djobanyene@gmail.com'),
        _tile(context, Icons.location_on, 'Adresse',
            'Goma, Nord-Kivu, RDC'),
        _tile(context, Icons.business_center, 'LinkedIn',
            'linkedin.com/in/banyene wetemwami jonathan',
            url: 'https://www.linkedin.com/in/Banyene Wetemwami jonathan'),
        _tile(context, Icons.code, 'GitHub', 'github.com/Banyene Wetemwami jonathan',
            url: 'https://github.com/Banyene Wetemwami jonathan'),
      ],
    );
  }
}
