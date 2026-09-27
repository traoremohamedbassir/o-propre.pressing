// import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pressing_opropre/view/admin/encaissement.dart';
// import 'package:intl/intl.dart';
import 'package:pressing_opropre/view/admin/rec_calcule.dart';
import 'package:pressing_opropre/view/constant/drawer.dart';

class Recette extends StatefulWidget {
  const Recette({super.key});

  @override
  State<Recette> createState() => _RecetteState();
}

class _RecetteState extends State<Recette> {
  final CollectionReference _recette = FirebaseFirestore.instance.collection(
    "recettes",
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool ischecked = true;
  // recherche date

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
  Future<void> _updaterecette(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final _nomcltController = TextEditingController(
      text: data['nom_clt']?.toString() ?? '',
    );
    final _sommeController = TextEditingController(
      text: data['montant']?.toString() ?? '',
    );
     final _numeroController = TextEditingController(
      text: data['numero']?.toString() ?? '',
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
              TextFormField(controller: _sommeController, decoration: const InputDecoration(labelText: 'montant')),
              const SizedBox(height: 8),
              TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'numero')),
              const SizedBox(height: 8),
             
              ],
          ),
        ),
       
       
        // 'numero': _numeroController.text.trim(),
        // 'montant': double.tryParse(_sommeController.text) ?? 0,
        // 'service': selectedser ?? 'lavage',
        // 'syspaiement ': selectedpaie ?? 'espece',
       
       
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'nom_clt': _nomcltController.text.trim(),
                'montant': _sommeController.text.trim(),
                'numero': _numeroController.text.trim(),
               
                });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    _nomcltController.dispose();
    _sommeController.dispose();
    _numeroController.dispose();
    

    if (updated == null) return;
    await _recette.doc(doc.id).update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:  Colors.blue.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          title: const Text(
            'Recette',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
             IconButton(
              tooltip: 'Encaissement',
              onPressed: (){
               Navigator.push(context, MaterialPageRoute(builder: (_)
                 => Encaissement(),
               ));
             }, icon: Icon(Icons.payment, color: Colors.white, size: 40)),
              SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecetteCalcul(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawers(),
        body: ListView(
          children: [
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou date (JJ/MM/AAAA)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      tooltip: 'Choisir une date',
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: _pickDateFilter,
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'liste des clients',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
          SizedBox(height: 20),
          Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _recetteStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

                  final docs = (snapshot.data?.docs ?? [])
                      .where((doc) => _matchesSearch(doc.data() as Map<String, dynamic>? ?? {}))
                      .toList();
                  if (docs.isEmpty) return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Aucune recette trouvé'),
                  );

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final nom = data['nom_clt']?.toString() ?? '';
                      final montant = (data['montant'] ?? 0).toString();
                      final service = data['service']?.toString();
                      final syspaiement = data['syspaiement ']?.toString();
                      final numero = data['numero']?.toString() ?? '';
                      String dateStr = '';
                      if (data['date'] is Timestamp) {
                        final d = (data['date'] as Timestamp).toDate();
                        dateStr = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                      } else if (data['date'] is String) {
                        dateStr = data['date'];
                      }
  
                      return ListTile(
                        title: Row(
                          children: [
                            Text(nom),
                            SizedBox(width: 20,),
                            Text(' -   $numero'),
                          ],
                        ),
                        subtitle: Column(
                          children: [
                            Text('Montant: $montant FCFA\nDate: $dateStr \nService: $service \npaiement : $syspaiement',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('retrait :',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                            ),
                                Checkbox(
                                  
                                value: data['retrait'] == true,
                                onChanged: (value) {
                                _recette.doc(doc.reference.id).update({
                                  'retrait': value
                                });
                                setState(() {
                                     showDialog(context: context, builder: (context) => Ajoutencaisse());
                                  });
                                 },
                                 activeColor: Colors.brown,
                              ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Checkbox(
                            value: data['payer'] == true,
                            onChanged: (value) {
                              _recette.doc(doc.reference.id).update({
                                'payer': value
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                           IconButton(
                              tooltip: 'Voir la liste',
                              icon: Icon(Icons.list,color: Colors.black,),
                              onPressed: () => _showProductsDialog(doc),
                            ),
                            IconButton(
                              tooltip: 'modifier',
                              icon: Icon(Icons.edit,color: Colors.green,),
                              onPressed: (){
                                _updaterecette(doc);
                              },
                            ),
                            IconButton(
                              tooltip: 'supprimer',
                              icon: Icon(Icons.delete,color: Colors.red,),
                              onPressed: (() async {
                                    await _recette
                                        .doc(doc.reference.id)
                                        .delete();
                                    
                                  }),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          ],
        )
      ),
    );
  }
  Stream<QuerySnapshot> _recetteStream() {
    return _recette.orderBy('date', descending: true).snapshots();
  }
  
  // affiche la liste des produits d'une recette
  void _showProductsDialog(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final produits = (data['produits'] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Text('Produits de ${data['nom_clt'] ?? ''}'),
            
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: produits.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final p = Map<String, dynamic>.from(produits[index] as Map<dynamic, dynamic>);
              final nomP = p['nom']?.toString() ?? '';
              final quantite = p['quantite']?.toString() ?? '';
              

              return ListTile(
                title: Row(
                  children: [
                    Text(nomP),
                    SizedBox(width: 10),
                    Text(quantite),
                  ],
                ),
               
              );
            },
            
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Fermer')),
        ],
      ),
    );
  }
   @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class Header extends StatelessWidget {
  final String tite, valeur, devise;
  const Header({
    super.key,
    required this.tite,
    required this.valeur,
    required this.devise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tite,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                devise,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}