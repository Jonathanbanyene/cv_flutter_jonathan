import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

// ============================================================
//  À MODIFIER selon comment tu testes :
//   - Téléphone en USB + "adb reverse" ou Edge : http://localhost/api-test/public
//   - Téléphone en Wi-Fi : http://IP_DE_TON_PC/api-test/public
//   - Émulateur Android : http://10.0.2.2/api-test/public
// ============================================================
const String baseUrl = 'http://localhost/api-test/public';

/// Affiche un petit message en bas de l'écran.
void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

String _s(dynamic v) => v?.toString() ?? '';

class Membre {
  final int id;
  final String nom, postnom, prenom, lieuNaissance, dateNaissance, parente;
  final String? imageUrl;

  Membre({
    required this.id,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.lieuNaissance,
    required this.dateNaissance,
    required this.parente,
    this.imageUrl,
  });

  factory Membre.fromJson(Map<String, dynamic> j) {
    final img = _s(j['image']);
    return Membre(
      id: int.parse(_s(j['id'])),
      nom: _s(j['nom']),
      postnom: _s(j['postnom']),
      prenom: _s(j['prenom']),
      lieuNaissance: _s(j['lieu_naissance']),
      dateNaissance: _s(j['date_naissance']),
      parente: _s(j['parente']),
      // On reconstruit l'URL avec notre baseUrl : ça marche aussi sur téléphone
      imageUrl: img.isEmpty ? null : '$baseUrl/$img',
    );
  }

  String get nomComplet => '$prenom $nom $postnom';

  Map<String, String> get champs => {
        'nom': nom,
        'postnom': postnom,
        'prenom': prenom,
        'lieu_naissance': lieuNaissance,
        'date_naissance': dateNaissance,
        'parente': parente,
      };
}

class Api {
  static const _json = {'Content-Type': 'application/json'};

  static dynamic _handle(http.Response r) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse invalide du serveur (code ${r.statusCode})');
    }
    if (body['success'] == true) return body['data'];

    var msg = _s(body['message']);
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) msg = errors.values.join('\n');
    throw ApiException(msg.isEmpty ? 'Erreur (code ${r.statusCode})' : msg);
  }

  static Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final r = await call().timeout(const Duration(seconds: 30));
      return _handle(r);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Impossible de joindre le serveur. Vérifie que XAMPP est démarré et que l\'adresse de l\'API est bonne.');
    }
  }

  // ---------- Comptes ----------
  static Future<void> register(String email, String password) async {
    await _send(() => http.post(
          Uri.parse('$baseUrl/accounts/register'),
          headers: _json,
          body: jsonEncode({'email': email, 'password': password}),
        ));
  }

  static Future<void> login(String email, String password) async {
    await _send(() => http.post(
          Uri.parse('$baseUrl/accounts/login'),
          headers: _json,
          body: jsonEncode({'email': email, 'password': password}),
        ));
  }

  // ---------- Membres de famille ----------
  static Future<List<Membre>> liste() async {
    final data = await _send(() => http.get(Uri.parse('$baseUrl/famille-membres')));
    return (data as List)
        .map((e) => Membre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Membre> un(int id) async {
    final data =
        await _send(() => http.get(Uri.parse('$baseUrl/famille-membres/$id')));
    return Membre.fromJson(data as Map<String, dynamic>);
  }

  /// Crée (id == null) ou modifie (id != null) un membre.
  /// Avec une image : POST en form-data. Sans image : POST ou PUT en JSON.
  static Future<void> enregistrer({
    int? id,
    required Map<String, String> champs,
    XFile? image,
  }) async {
    final url = id == null
        ? '$baseUrl/famille-membres'
        : '$baseUrl/famille-membres/$id';

    if (image != null) {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      await _send(() async {
        final req = http.MultipartRequest('POST', Uri.parse(url))
          ..fields.addAll(champs)
          ..files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
            contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
          ));
        return http.Response.fromStream(await req.send());
      });
    } else if (id == null) {
      await _send(() =>
          http.post(Uri.parse(url), headers: _json, body: jsonEncode(champs)));
    } else {
      await _send(() =>
          http.put(Uri.parse(url), headers: _json, body: jsonEncode(champs)));
    }
  }

  static Future<void> supprimer(int id) async {
    await _send(() => http.delete(Uri.parse('$baseUrl/famille-membres/$id')));
  }
}
