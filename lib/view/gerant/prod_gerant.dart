import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

class ProdGerant extends StatefulWidget {
  const ProdGerant({super.key});

  @override
  State<ProdGerant> createState() => _ProdGerantState();
}

class _ProdGerantState extends State<ProdGerant> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CollectionReference _produit = FirebaseFirestore.instance.collection(
    "produits",
  );
// rechercher
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

   // mise a jour
  Future<void> _updateproduit(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nomController = TextEditingController(
      text: data['nom']?.toString() ?? '',
    );
    final prixController = TextEditingController(
      text: data['prix']?.toString() ?? '',
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
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 8),
              TextField(controller: prixController, decoration: const InputDecoration(labelText: 'Prixt')),
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
                'nom': nomController.text.trim(),
                'prix': prixController.text.trim(),
                });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    nomController.dispose();
    prixController.dispose();
    

    if (updated == null) return;
    await _produit.doc(doc.id).update(updated);
  }


  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
       backgroundColor:  Colors.blue.shade100,
        appBar: AppBar(
          title: Text('Produits'),
          backgroundColor: Colors.blue.shade700,
          actions: [
             Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                     showDialog(context: context, builder: (context) => Ajout());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                const SizedBox(height: 20),
                Text(
                  'Liste des produits de lavage',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // rechercher
                Row(
                  // recherche et imprimer
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value.trim().toLowerCase());
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit ou fournisseur',
                          prefixIcon: const Icon(Icons.search),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 8),
              StreamBuilder<QuerySnapshot>(
              stream: _produit.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('pas de donnees'));
                }

                final rows = snapshot.data!.docs.map((doc) {
                  return DataRow(
                    selected: true,
                    cells: [
                      DataCell(Text(doc['nom']?.toString() ?? '')),
                      DataCell(Text(doc['prix']?.toString() ?? '')),
                     
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await _produit.doc(doc.reference.id).delete();
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                            IconButton(
                              onPressed: () => _updateproduit(doc),
                              icon: Icon(Icons.edit, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'nom',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'prix',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                       
                        DataColumn(
                          label: Text(
                            'actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      rows: rows,
                    ),
                  ),
                );
              },
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ////////////////////////////////////////////////////////////////////
// textformulaire pour ajouter
class Ajout extends StatefulWidget {
  const Ajout({super.key});

  @override
  State<Ajout> createState() => _AjoutState();
}

class _AjoutState extends State<Ajout> {
  final TextEditingController _nomController = TextEditingController();

  final TextEditingController _prixController = TextEditingController();

  
final _formKey = GlobalKey<FormState>();
  final CollectionReference _produit = FirebaseFirestore.instance.collection(
    "produits",
  );
 

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      // title: Text('Ajouter un article'),
      
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IconButton(
            //   onPressed: () {
            //     // Navigator.pop(context)
            //   },
            //   icon: Icon(Icons.barcode_reader),
            // ),
            SizedBox(height: 10),
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                hintText: 'Nom du produit',
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Le nom est requis';
                    return null;
                  },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              controller: _prixController,
              decoration: InputDecoration(
                hintText: "Prix",
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le prix est requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez un montant valide';
                  return null;
                },
            ),
        
        
            
        
           
        
            SizedBox(height: 6),
            // textforme(hinttext: 'Code bare / QR code'),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await _produit.add({
                  'nom': _nomController.text.trim(),
                  
                  'prix': _prixController.text.trim(),
                 
                });
               
                setState(() {
                  Navigator.pop(context);
                _nomController.clear();
                _prixController.clear();
               
                });
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      ],
    );
  }
}
// ////////////////////////////////////////////////
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
