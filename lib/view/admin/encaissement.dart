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
          //  'nom_clt': _nomcltController.text,
          //         'date': _dateController.text,
          //         'montant': _montantContoller.text,
          //         'description': _descriptionContoller.text,
          //         'syspaiement ': selectedpaie ?? 'espece',
          //         'montant_facture': _mon_factContoller.text,
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
        title: Text('Encaissement'),
        actions: [
             IconButton(
              tooltip: 'Recette',
              onPressed: (){
               Navigator.push(context, MaterialPageRoute(builder: (_)
                 => Recette(),
               ));
             }, icon: Icon(Icons.receipt, color: Colors.white, size: 40)),
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
                   showDialog(context: context, builder: (context) => Ajoutencaisse());
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ),
      ],),
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
         Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _encaisseStream(),
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
                    child: Text('Aucun resultat trouvé'),
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
                      final description = data['description']?.toString();
                      final syspaiement = data['syspaiement ']?.toString();
                      final montant_facture = data['montant_facture']?.toString() ?? '';
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
                            Text('$nom',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20
                            ),
                            ),
                            SizedBox(width: 20,),
                            Text(' -   $montant FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20
                            ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          children: [
                            Text('systeme de paiement : $syspaiement \n montant de la facture : $montant_facture \n descriptions : $description \n Date: $dateStr',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            ),
                           
                          ],
                        ),
                       
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          
                            IconButton(
                              tooltip: 'modifier',
                              icon: Icon(Icons.edit,color: Colors.green,),
                              onPressed: (){
                                _updateencaissement(doc);
                              },
                            ),
                            IconButton(
                              tooltip: 'supprimer',
                              icon: Icon(Icons.delete,color: Colors.red,),
                              onPressed: (() async {
                                    await _encaisse
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
class Ajoutencaisse extends StatefulWidget {
  const Ajoutencaisse({super.key});

  @override
  State<Ajoutencaisse> createState() => _AjoutencaisseState();
}

class _AjoutencaisseState extends State<Ajoutencaisse> {
  String? selectedpaie = "espece";
  final TextEditingController _nomcltController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _mon_factController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
  final CollectionReference _encaisse = FirebaseFirestore.instance.collection(
    "encaissement",
  );
 

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            SizedBox(height: 4),
            TextFormField(
              controller: _nomcltController,
              decoration: InputDecoration(
                hintText: 'Nom clt',
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
        
            SizedBox(height: 4),
            TextFormField(
              controller: _montantController,
              decoration: InputDecoration(
                hintText: "montant",
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
                    if (value == null || value.trim().isEmpty) return 'Le montant est requis';
                    return null;
                  },
            ),
             SizedBox(height: 4),
            TextFormField(
              controller: _mon_factController,
              decoration: InputDecoration(
                hintText: "montant de la facture",
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
                    if (value == null || value.trim().isEmpty) return 'Le montant est requis';
                    return null;
                  },
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "description",
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
                    if (value == null || value.trim().isEmpty) return 'Le montant est requis';
                    return null;
                  },
            ),
            SizedBox(height: 4),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: selectedpaie,
                      isExpanded: true,
                      hint: Text('systeme depaiement'),

                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'espece',
                          child: Text('espece'),
                        ),
                        DropdownMenuItem(
                          value: 'wave',
                          child: Text('wave'),
                        ),
                        DropdownMenuItem(
                          value: 'orange money',
                          child: Text('orange money'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          selectedpaie = value ?? 'espece';
                        });
                      },
                    ),
                  ),
                ),
            SizedBox(height: 4),
            TextFormField(
              controller: _dateController,
                    readOnly: true,
              decoration: InputDecoration(
                hintText: 'date',
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
              
            ),
            SizedBox(height: 6),
           
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
                
                await _encaisse.add({
                  'nom_clt': _nomcltController.text,
                  'date': _dateController.text,
                  'montant': _montantController.text,
                  'description': _descriptionController.text,
                  'syspaiement ': selectedpaie ?? 'espece',
                  'montant_facture': _mon_factController.text,
                });
                _nomcltController.clear();
                _dateController.clear();
                _montantController.clear();
                
                setState(() {
                  Navigator.pop(context);
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