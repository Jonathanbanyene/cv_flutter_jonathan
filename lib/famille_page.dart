import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';

// ------------------------------------------------------------
//  Photo ronde chargée depuis Internet (ou icône si pas de photo)
// ------------------------------------------------------------
class NetPhoto extends StatelessWidget {
  final String? url;
  final double size;

  const NetPhoto({super.key, this.url, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.grey),
    );
    if (url == null) return ClipOval(child: fallback);
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}

// ------------------------------------------------------------
//  PAGE 3 : FAMILLE (liste + ajout + modification + suppression)
// ------------------------------------------------------------
class FamillePage extends StatefulWidget {
  const FamillePage({super.key});

  @override
  State<FamillePage> createState() => _FamillePageState();
}

class _FamillePageState extends State<FamillePage> {
  late Future<List<Membre>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.liste();
  }

  Future<void> _reload() async {
    setState(() => _future = Api.liste());
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _ouvrirFormulaire([Membre? m]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MembreFormPage(membre: m)),
    );
    if (ok == true) _reload();
  }

  Future<void> _supprimer(Membre m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer ${m.nomComplet} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.supprimer(m.id);
      if (!mounted) return;
      toast(context, 'Membre supprimé');
      _reload();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirFormulaire(),
        child: const Icon(Icons.person_add),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Membre>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton(
                        onPressed: _reload, child: const Text('Réessayer')),
                  ),
                ],
              );
            }
            final membres = snap.data!;
            if (membres.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Aucun membre. Appuie sur + pour en ajouter.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: membres.length,
              itemBuilder: (context, i) {
                final m = membres[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    leading: NetPhoto(url: m.imageUrl),
                    title: Text(m.nomComplet,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${m.parente} · ${m.lieuNaissance}\nNé(e) le ${m.dateNaissance}'),
                    isThreeLine: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MembreDetailPage(id: m.id)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Modifier',
                          onPressed: () => _ouvrirFormulaire(m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: () => _supprimer(m),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
//  DÉTAIL d'un membre (GET /famille-membres/{id})
// ------------------------------------------------------------
Widget _ligne(IconData icon, String label, String value) =>
    ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));

class MembreDetailPage extends StatelessWidget {
  final int id;

  const MembreDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails')),
      body: FutureBuilder<Membre>(
        future: Api.un(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final m = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: NetPhoto(url: m.imageUrl, size: 140)),
              const SizedBox(height: 16),
              Center(
                child: Text(m.nomComplet,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 16),
              _ligne(Icons.family_restroom, 'Lien de parenté', m.parente),
              _ligne(Icons.location_on, 'Lieu de naissance', m.lieuNaissance),
              _ligne(Icons.cake, 'Date de naissance', m.dateNaissance),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
//  FORMULAIRE : ajout (membre == null) ou modification
// ------------------------------------------------------------
class MembreFormPage extends StatefulWidget {
  final Membre? membre;

  const MembreFormPage({super.key, this.membre});

  @override
  State<MembreFormPage> createState() => _MembreFormPageState();
}

class _MembreFormPageState extends State<MembreFormPage> {
  static const _labels = {
    'nom': 'Nom',
    'postnom': 'Postnom',
    'prenom': 'Prénom',
    'lieu_naissance': 'Lieu de naissance',
    'date_naissance': 'Date de naissance',
    'parente': 'Lien de parenté (Père, Mère, Frère…)',
  };

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c = {
    for (final k in _labels.keys)
      k: TextEditingController(text: widget.membre?.champs[k]),
  };
  XFile? _image;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_c['date_naissance']!.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      _c['date_naissance']!.text = d.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _choisirImage() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (f != null) setState(() => _image = f);
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Api.enregistrer(
        id: widget.membre?.id,
        champs: {for (final e in _c.entries) e.key: e.value.text.trim()},
        image: _image,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final edition = widget.membre != null;

    return Scaffold(
      appBar: AppBar(title: Text(edition ? 'Modifier le membre' : 'Ajouter un membre')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final k in _labels.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _c[k],
                  readOnly: k == 'date_naissance',
                  onTap: k == 'date_naissance' ? _pickDate : null,
                  decoration: InputDecoration(
                    labelText: _labels[k],
                    border: const OutlineInputBorder(),
                    suffixIcon: k == 'date_naissance'
                        ? const Icon(Icons.calendar_today)
                        : null,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
              ),
            OutlinedButton.icon(
              onPressed: _choisirImage,
              icon: const Icon(Icons.photo),
              label: Text(_image == null ? 'Choisir une photo' : 'Photo : ${_image!.name}'),
            ),
            if (edition && _image == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('La photo actuelle est conservée si tu n\'en choisis pas une autre.',
                    style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _envoyer,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(edition ? 'Enregistrer les modifications' : 'Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
