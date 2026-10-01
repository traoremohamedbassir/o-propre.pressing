import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pressing_opropre/Controller/auth.dart';
import 'package:pressing_opropre/connexion/login.dart';
import 'package:pressing_opropre/view/gerant/prod_gerant.dart';
import 'package:pressing_opropre/view/gerant/recette_gerant.dart';

class Homegerant extends StatefulWidget {
  const Homegerant({super.key});

  @override
  State<Homegerant> createState() => _HomegerantState();
}

class _HomegerantState extends State<Homegerant> {
  final AuthService _authService = AuthService();
  String _userName = '';
  late Stream<Map<String, dynamic>> _statsStream;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _statsStream = _watchEncaissementStats();
  }

  Stream<Map<String, dynamic>> _watchEncaissementStats() {
    return FirebaseFirestore.instance
        .collection('encaissement')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      double recetteDuJour = 0;
      double recetteMensuelle = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final montant = _toDouble(data['montant']);

        DateTime? parsed;
        if (data['date'] is Timestamp) {
          parsed = (data['date'] as Timestamp).toDate();
        } else {
          parsed = _parseDate(data['date']?.toString() ?? '');
        }

        if (parsed == null && data['created_at'] != null) {
          if (data['created_at'] is Timestamp) {
            parsed = (data['created_at'] as Timestamp).toDate();
          } else {
            parsed = _parseDate(data['created_at']?.toString() ?? '');
          }
        }

        if (_isSameDay(parsed, now)) {
          recetteDuJour += montant;
        }

        if (parsed != null && parsed.year == now.year && parsed.month == now.month) {
          recetteMensuelle += montant;
        }
      }

      return {
        'recetteDuJour': recetteDuJour,
        'recetteMensuelle': recetteMensuelle,
      };
    });
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }
// rec
  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    final v = value.trim();
    final patterns = ['dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd', 'yyyy/MM/dd', 'dd/MM/yy'];
    for (final p in patterns) {
      try {
        return DateFormat(p).parseStrict(v);
      } catch (_) {}
    }
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime? value, DateTime now) {
    if (value == null) return false;
    return value.year == now.year && value.month == now.month && value.day == now.day;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} M FCFA';
    return '${value.toStringAsFixed(0)} FCFA';
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted) return;

    setState(() {
      _userName = userSnapshot.data()?['name']?.toString().trim() ?? '';
      if (_userName.isEmpty) _userName = user.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      appBar: AppBar(
        title: Text("O'Propre Pressing",style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white),),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de bienvenue
              Row(
                children: [
                Expanded(
                  child: HeaderEmpl(
                    name: 'Bienvenue',
                    valeur: _userName,
                  ),
                ),
                ],
              ),
              const SizedBox(height: 30),
              // Titre des sections
              const Text(
                'Sections principales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),

              // Cards des sections
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSectionCard(
                    context,
                    image: 'lib/assets/recette/recette.PNG',
                    title: 'Recettes',
                    subtitle: 'Gérer les recettes',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      // Navigation vers recette_empl
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return RecetteGerant();
                          },
                        ),
                      );
                    },
                  ),
                  _buildSectionCard(
                    context,
                    image: 'lib/assets/produit/produit.PNG',
                    title: 'Produits',
                    subtitle: 'Gérer les produits',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      // Navigation vers stock_empl
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ProdGerant();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Section stats rapides
              const Text(
                'Résumé rapide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<Map<String, dynamic>>(
                stream: _statsStream,
                builder: (context, snap) {
                  final data = snap.data ?? {'recetteDuJour': 0.0, 'recetteMensuelle': 0.0};
                  final recette = (data['recetteDuJour'] as double?) ?? 0.0;
                  final mensuelle = (data['recetteMensuelle'] as double?) ?? 0.0;

                  return Column(
                    children: [
                      _buildStatCard('Recettes journalière', _formatCurrency(recette), const Color(0xFF4CAF50)),
                      const SizedBox(height: 12),
                      _buildStatCard('Recettes mensuelles', _formatCurrency(mensuelle), const Color(0xFFFF9800)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {

    required String title,
    image,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Image.asset(image, width: 68),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderEmpl extends StatelessWidget {
  final String name, valeur;
  const HeaderEmpl({super.key, required this.name, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.blue,
            Color.fromARGB(255, 102, 165, 216),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 19,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
