// import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
                hintText: 'Rechercher un client par nom',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer la recherche',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'leste des cl',
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

                  final docs = snapshot.data?.docs ?? [];
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
                      // final paiement = data['payer']?.toString();
                      String dateStr = '';
                      if (data['date'] is Timestamp) {
                        final d = (data['date'] as Timestamp).toDate();
                        dateStr = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                      } else if (data['date'] is String) {
                        dateStr = data['date'];
                      }

                      return ListTile(
                        title: Text(nom),
                        subtitle: Column(
                          children: [
                            Text('Montant: $montant FCFA\nDate: $dateStr \nService: $service',
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
                              onPressed: (){},
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
    if (_searchQuery.isEmpty) {
      return _recette.orderBy('date', descending: true).snapshots();
    }

    // prefix search on nom_clt
    final start = _searchQuery;
    final end = '$_searchQuery\uf8ff';
    return _recette
        .where('nom_clt', isGreaterThanOrEqualTo: start)
        .where('nom_clt', isLessThanOrEqualTo: end)
        .orderBy('nom_clt')
        .snapshots();
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
                title: Text(nomP),
                subtitle: Text('Quantité: $quantite'),
                // trailing: Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     Text(retrait ? 'Retiré' : 'En attente'),
                //     SizedBox(width: 8),
                //     Checkbox(
                //       value: retrait,
                //       onChanged: (val) async {
                //         // Met à jour localement la liste et dans firestore
                //         final updated = List<Map<String, dynamic>>.from(produits.map((e) 
                //         => Map<String, dynamic>.from(e as Map)));
                //         updated[index]['retrait'] = val == true;
                //         await _recette.doc(doc.reference.id).update({'produits': updated});
                //         setState(() {});
                //         Navigator.of(context).pop();
                //         // rouvrir le dialogue pour rafraichir
                //         Future.delayed(Duration(milliseconds: 100), () => _showProductsDialog(doc));
                //       },
                //     ),
                //   ],
                // ),
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
