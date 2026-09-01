// import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:pressing_opropre/view/admin/rec_calcule.dart';

class RecetteGerant extends StatefulWidget {
  const RecetteGerant({super.key});

  @override
  State<RecetteGerant> createState() => _RecetteGerantState();
}

class _RecetteGerantState extends State<RecetteGerant> {
  final CollectionReference _recette = FirebaseFirestore.instance.collection(
    "recettes",
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
bool ischecked = true;

  // double _toDouble(dynamic value) {
  //   if (value is num) return value.toDouble();
  //   if (value is String) return double.tryParse(value) ?? 0;
  //   return 0;
  // }

  // DateTime? _parseDate(String value) {
  //   if (value.trim().isEmpty) return null;

  //   final cleaned = value.trim();
  //   final patterns = ['dd/MM/yyyy', 'dd/MM/yy', 'yyyy-MM-dd', 'yyyy/MM/dd'];

  //   for (final pattern in patterns) {
  //     try {
  //       return DateFormat(pattern).parseStrict(cleaned);
  //     } catch (_) {}
  //   }

  //   try {
  //     return DateTime.parse(cleaned);
  //   } catch (_) {
  //     return null;
  //   }
  // }

  // bool _isSameDay(DateTime? value, DateTime now) {
  //   if (value == null) return false;
  //   return value.year == now.year &&
  //       value.month == now.month &&
  //       value.day == now.day;
  // }

  // String _safeStringValue(Map<String, dynamic>? data, String key) {
  //   if (data == null || !data.containsKey(key)) return '';
  //   return data[key]?.toString() ?? '';
  // }

//  mise a jour
  // Future<void> _updateRecette(QueryDocumentSnapshot doc) async {
  //   final data = doc.data() as Map<String, dynamic>? ?? {};
  //   final dateController = TextEditingController(text: _safeStringValue(data, 'date'));
  //   final clientController = TextEditingController(text: _safeStringValue(data, 'nom_clt'));
  //   final montantController = TextEditingController(text: _toDouble(data['montant']).toStringAsFixed(0));
  //   var paiement = _safeStringValue(data, 'paiement');

  //   final values = await showDialog<Map<String, dynamic>>(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setDialogState) => AlertDialog(
  //         backgroundColor: Colors.white,
  //         title: const Text('Mettre à jour la recette'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
  //               TextField(controller: clientController, decoration: const InputDecoration(labelText: 'Nom du client')),
  //               TextField(
  //                 controller: montantController,
  //                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //                 decoration: const InputDecoration(labelText: 'Montant'),
  //               ),
  //               DropdownButtonFormField<String>(
  //                 value: paiement.isEmpty ? null : paiement,
  //                 decoration: const InputDecoration(labelText: 'Paiement'),
  //                 items: const [
  //                   DropdownMenuItem(value: 'espece', child: Text('espece')),
  //                   DropdownMenuItem(value: 'mobile', child: Text('mobile money')),
  //                   DropdownMenuItem(value: 'credit', child: Text('credit')),
  //                   DropdownMenuItem(value: 'virement', child: Text('virement')),
  //                   DropdownMenuItem(value: 'en attente', child: Text('en attente')),
  //                 ],
  //                 onChanged: (value) => setDialogState(() => paiement = value ?? ''),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
  //           FilledButton(
  //             onPressed: () => Navigator.pop(context, {
  //               'date': dateController.text.trim(),
  //               'nom_clt': clientController.text.trim(),
  //               'montant': _toDouble(montantController.text.replaceAll(',', '.')),
  //               'paiement': paiement,
  //             }),
  //             child: const Text('Mettre à jour'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //   dateController.dispose();
  //   clientController.dispose();
  //   montantController.dispose();
  //   if (values == null) return;

  //   final stockSnapshot = await FirebaseFirestore.instance.collection('stocks').get();
  //   final purchasePrices = <String, double>{};
  //   for (final stock in stockSnapshot.docs) {
  //     final stockData = stock.data();
  //     final name = stockData['nom_produit']?.toString();
  //     if (name != null) purchasePrices[name] = _toDouble(stockData['prix_achat']);
  //   }

  //   final products = ((data['produits'] as List<dynamic>?) ?? const []).map((product) {
  //     final item = Map<String, dynamic>.from(product as Map);
  //     final name = item['nom_produit']?.toString() ?? '';
  //     item['prix_achat'] = _toDouble(item['prix_achat'] ?? purchasePrices[name]);
  //     return item;
  //   }).toList();
  //   final updatedData = {...values, 'produits': products};
  //   updatedData['benefice'] = _recipeProfit(updatedData);
  //   await _recette.doc(doc.id).update(updatedData);
  // }

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

 
