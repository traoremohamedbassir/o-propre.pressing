import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pressing_opropre/view/admin/recette.dart';
import 'package:pressing_opropre/view/constant/drawer.dart';

class Encaissement extends StatefulWidget {
  const Encaissement({super.key});

  @override
  State<Encaissement> createState() => _EncaissementState();
}

class _EncaissementState extends State<Encaissement> {
final CollectionReference _encaisse = FirebaseFirestore.instance.collection(
    "encaissement",
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
bool ischecked = true;

  DateTime? _parseDateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is! String) return null;

    final text = value.trim();
    if (text.isEmpty) return null;

    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
    ];

    for (final pattern in formats) {
      try {
        final date = _parseDateString(text, pattern);
        if (date != null) return date;
      } catch (_) {}
    }

    return null;
  }

  DateTime? _parseDateString(String value, String pattern) {
    final parts = value.split(RegExp(r'[/\-]'));
    if (parts.length != 3) return null;

    int day = 0;
    int month = 0;
    int year = 0;

    if (pattern == 'dd/MM/yyyy' || pattern == 'dd-MM-yyyy') {
      day = int.tryParse(parts[0]) ?? 0;
      month = int.tryParse(parts[1]) ?? 0;
      year = int.tryParse(parts[2]) ?? 0;
    } else {
      year = int.tryParse(parts[0]) ?? 0;
      month = int.tryParse(parts[1]) ?? 0;
      day = int.tryParse(parts[2]) ?? 0;
    }

    if (day == 0 || month == 0 || year == 0) return null;

    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) return null;
    return date;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return true;

    final nom = (data['nom_clt'] ?? '').toString().toLowerCase();
    if (nom.contains(query.toLowerCase())) return true;

    final itemDate = _parseDateFromValue(data['date']);
    if (itemDate == null) return false;

    final selectedDate = _parseDateString(query, 'dd/MM/yyyy');
    if (selectedDate == null) return false;

    return itemDate.year == selectedDate.year &&
        itemDate.month == selectedDate.month &&
        itemDate.day == selectedDate.day;
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    setState(() {
      _searchController.text = formatted;
      _searchQuery = formatted;
    });
  }

// mise a jour
  Future<void> _updateencaissement(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final _nomcltController = TextEditingController(
      text: data['nom_clt']?.toString() ?? '',
    );
    final _montantController = TextEditingController(
      text: data['montant']?.toString() ?? '',
    );
     final _mon_factController = TextEditingController(
      text: data['montant_facture']?.toString() ?? '',
    );
    final _descriptionController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier le produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nomcltController, decoration: const InputDecoration(labelText: 'Nom client')),
              const SizedBox(height: 8),
              TextFormField(controller: _montantController, decoration: const InputDecoration(labelText: 'montant apres reduction')),
              const SizedBox(height: 8),
              TextFormField(controller: _mon_factController, decoration: const InputDecoration(labelText: 'montant de la facture')),
              const SizedBox(height: 8),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'description')),
              const SizedBox(height: 8),
              ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'nom_clt': _nomcltController.text.trim(),
                'montant': _montantController.text.trim(),
                'montant_facture': _mon_factController.text.trim(),
                'description': _descriptionController.text.trim(),
                });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    _nomcltController.dispose();
    _montantController.dispose();
    

    if (updated == null) return;
    await _encaisse.doc(doc.id).update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor:  Colors.blue.shade100,
      appBar: AppBar(
       backgroundColor:  Colors.blue.shade700,
        elevation: 0,
        title: const Text(
          'Encaissement',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Recette',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Recette()),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const Drawers(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou date (JJ/MM/AAAA)',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.clear, color: Colors.teal),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      tooltip: 'Choisir une date',
                      icon: const Icon(Icons.calendar_today_outlined, color: Colors.teal),
                      onPressed: _pickDateFilter,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF99F6E4), width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historique encaissements',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _encaisseStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Erreur: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snapshot.data?.docs ?? [])
                      .where(
                        (doc) =>
                            _matchesSearch(doc.data() as Map<String, dynamic>? ?? {}),
                      )
                      .toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucun résultat trouvé'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final nom = data['nom_clt']?.toString() ?? '';
                      final montant = (data['montant'] ?? 0).toString();
                      final description = data['description']?.toString() ?? '—';
                      final syspaiement = data['syspaiement ']?.toString() ?? '—';
                      final montantFacture = data['montant_facture']?.toString() ?? '—';
                      String dateStr = '';
                      if (data['date'] is Timestamp) {
                        final d = (data['date'] as Timestamp).toDate();
                        dateStr =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                      } else if (data['date'] is String) {
                        dateStr = data['date'];
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nom,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$montant FCFA',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF115E59),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(label: 'Date', value: dateStr),
                              _InfoRow(label: 'Paiement', value: syspaiement),
                              _InfoRow(label: 'Facture', value: montantFacture),
                              _InfoRow(label: 'Description', value: description),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Modifier',
                                    icon: const Icon(Icons.edit, color: Colors.green),
                                    onPressed: () => _updateencaissement(doc),
                                  ),
                                  IconButton(
                                    tooltip: 'Supprimer',
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _encaisse.doc(doc.reference.id).delete();
                                    },
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _encaisseStream() {
    return _encaisse.orderBy('date', descending: true).snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}