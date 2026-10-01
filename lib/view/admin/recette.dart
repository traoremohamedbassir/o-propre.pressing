
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pressing_opropre/view/admin/encaissement.dart';
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

  Future<void> _ajoutEnCaisseDepuisRecette(Map<String, dynamic> data, String docId) async {
    if (data['payer'] == true) {
      return;
    }

    final nomClient = (data['nom_clt'] ?? '').toString();
    final montantRecette = (data['montant'] ?? 0).toString();
    final dateRecette = (() {
      final dateValue = data['date'];
      if (dateValue is Timestamp) {
        final d = dateValue.toDate();
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      if (dateValue is DateTime) {
        final d = dateValue;
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      return dateValue?.toString() ?? '';
    })();
    final typePaiement = (data['syspaiement '] ?? 'espece').toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Ajoutencaisse(
        nomClient: nomClient,
        date: dateRecette,
        montantFacture: montantRecette,
        typePaiement: typePaiement,
      ),
    );

    if (result == true) {
      await _recette.doc(docId).update({'payer': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
       backgroundColor:  Colors.blue.shade100,
        appBar: AppBar(
         backgroundColor:  Colors.blue.shade700,
          elevation: 0,
          title: const Text(
            'Recette',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: 'Encaissement',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Encaissement()),
                );
              },
              icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(6),
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
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.clear, color: Colors.blueGrey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      IconButton(
                        tooltip: 'Choisir une date',
                        icon: const Icon(Icons.calendar_today_outlined, color: Colors.blueGrey),
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
                    borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.5),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Liste des clients',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _recetteStream(),
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
                        child: Text('Aucune recette trouvée'),
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
                        final service = data['service']?.toString() ?? '—';
                        final syspaiement = data['syspaiement ']?.toString() ?? '—';
                        final numero = data['numero']?.toString() ?? '—';
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
                                blurRadius: 10,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'N° $numero',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$montant FCFA',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _InfoRow(label: 'Date', value: dateStr),
                                _InfoRow(label: 'Service', value: service),
                                _InfoRow(label: 'Paiement', value: syspaiement),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Retrait',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          Checkbox(
                                            value: data['retrait'] == true,
                                            onChanged: (value) {
                                              _recette.doc(doc.reference.id).update({
                                                'retrait': value,
                                              });
                                            },
                                            activeColor: const Color(0xFF7C3AED),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: data['payer'] == true,
                                      onChanged: (value) async {
                                        if (value == true) {
                                          await _ajoutEnCaisseDepuisRecette(
                                            data,
                                            doc.reference.id,
                                          );
                                          return;
                                        }

                                        await _recette.doc(doc.reference.id).update({
                                          'payer': false,
                                        });
                                      },
                                      activeColor: Colors.green,
                                      side: const BorderSide(color: Colors.green),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Payé',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showProductsDialog(doc),
                                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                                      label: const Text('Détails'),
                                    ),
                                    IconButton(
                                      tooltip: 'Modifier',
                                      icon: const Icon(Icons.edit, color: Colors.green),
                                      onPressed: () => _updaterecette(doc),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await _recette.doc(doc.reference.id).delete();
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

class Ajoutencaisse extends StatefulWidget {
  const Ajoutencaisse({
    super.key,
    this.nomClient = '',
    this.date = '',
    this.montantFacture = '',
    this.typePaiement = 'espece',
  });

  final String nomClient;
  final String date;
  final String montantFacture;
  final String typePaiement;

  @override
  State<Ajoutencaisse> createState() => _AjoutencaisseState();
}

class _AjoutencaisseState extends State<Ajoutencaisse> {
  String? selectedpaie;
  final TextEditingController _nomcltController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _mon_factController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedpaie = widget.typePaiement.isNotEmpty ? widget.typePaiement : 'espece';
    _nomcltController.text = widget.nomClient;
    _mon_factController.text = widget.montantFacture;
    _montantController.text = widget.montantFacture;
    _dateController.text = widget.date.isNotEmpty
        ? widget.date
        : '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
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
                  'nom_clt': _nomcltController.text.trim(),
                  'date': _dateController.text.trim(),
                  'montant': _montantController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'syspaiement ': selectedpaie ?? 'espece',
                  'montant_facture': _mon_factController.text.trim(),
                });
                _nomcltController.clear();
                _dateController.clear();
                _montantController.clear();
                _mon_factController.clear();
                _descriptionController.clear();

                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      ],
    );
  }
}