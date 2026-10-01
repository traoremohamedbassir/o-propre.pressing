import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProductRowData {
  ProductRowData();

  String? selectedProduit;
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prixController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
}

class RecetteCalcul extends StatefulWidget {
  const RecetteCalcul({super.key});

  @override
  State<RecetteCalcul> createState() => _RecetteCalculState();
}

class _RecetteCalculState extends State<RecetteCalcul> {
  final CollectionReference _produit = FirebaseFirestore.instance.collection(
    'produits',
  );
  final CollectionReference _recette = FirebaseFirestore.instance.collection(
    "recettes",
  );
  String? selectedser = "lavage";
  String? selectedpaie = "espece";
  final List<ProductRowData> _rows = [ProductRowData()];
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nomcltController = TextEditingController();
  final TextEditingController _sommeController = TextEditingController();
  final TextEditingController _numfactController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final List<String> _produits = [];
  final Map<String, dynamic> _produitPrix = {};
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _lastInvoice;
  bool _isSaving = false;
  bool _isManualTotal = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _todayDate();
    _loadNextInvoiceNumber();
    _loadProduits();
  }
// num facture
  Future<void> _loadNextInvoiceNumber() async {
    final counter = await FirebaseFirestore.instance
        .collection('parametres')
        .doc('compteur_facture')
        .get();
    if (!mounted) return;
    final nextNumber = (counter.data()?['next'] as num?)?.toInt() ?? 1;
    _numfactController.text = nextNumber.toString();
  }


// enregistrement
  Future<void> _saveInvoice() async {
    if (_isSaving) return;

    // if (_nomcltController.text.trim().isEmpty) {
    //   _showMessage('Le nom du client est requis.');
    //   return;
    // }
    if (!_formKey.currentState!.validate()) return;
    // table produit
    final products = _rows
        .where((row) => row.nomController.text.trim().isNotEmpty)
        .map(
          (row) => {
            'nom': row.nomController.text.trim(),
            'quantite': double.tryParse(row.quantiteController.text) ?? 0,
            'prix': double.tryParse(row.prixController.text) ?? 0,
            
          },
        )
        .toList();

    if (products.isEmpty) {
      _showMessage('Ajoutez au moins un produit.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final counterRef = FirebaseFirestore.instance
          .collection('parametres')
          .doc('compteur_facture');
      final invoiceRef = _recette.doc();
      late int invoiceNumber;

      final stockSnapshot = await _produit.get();
      final stockByProductName = <String, QueryDocumentSnapshot>{};
      for (final stockDoc in stockSnapshot.docs) {
        final name = (stockDoc.data() as Map<String, dynamic>? ?? {})['nom']
            ?.toString()
            .trim();
        if (name != null && name.isNotEmpty) {
          stockByProductName[name] = stockDoc;
        }
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);
        invoiceNumber = (counterSnapshot.data()?['next'] as num?)?.toInt() ?? 1;
        transaction.set(counterRef, {'next': invoiceNumber + 1});


        final currentUser = FirebaseAuth.instance.currentUser;
        transaction.set(invoiceRef, {
          'date': _dateController.text,
          'nom_clt': _nomcltController.text.trim(),
          'numero': _numeroController.text.trim(),
          'montant': double.tryParse(_sommeController.text) ?? 0,
          'service': selectedser ?? 'lavage',
          'syspaiement ': selectedpaie ?? 'espece',
          'num_facture': invoiceNumber,
          'produits': products,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': currentUser?.uid ?? '',
          'user_email': currentUser?.email ?? '',
        });
      });

      _lastInvoice = {
        'date': _dateController.text,
        'nom_clt': _nomcltController.text.trim(),
        'numero': _numeroController.text.trim(),
        'montant': double.tryParse(_sommeController.text) ?? 0,
        'service': selectedser ?? 'lavage',
        'syspaiement ': selectedpaie ?? 'espece',
        'num_facture': invoiceNumber,
        'produits': products,
      };
      _showMessage('Facture N° $invoiceNumber enregistrée.');
      _clearForm();
    } catch (_) {
      _showMessage('Impossible d’enregistrer la facture.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _numfactController.clear();
    _nomcltController.clear();
    _sommeController.clear();
    _isManualTotal = false;
    setState(() {
      selectedser = 'lavage';
      _rows
        ..clear()
        ..add(ProductRowData());
    });
    _loadNextInvoiceNumber();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  

  @override
  void dispose() {
    _dateController.dispose();
    _nomcltController.dispose();
    _sommeController.dispose();
    _numfactController.dispose();
    _numeroController.dispose();
    for (final row in _rows) {
      row.nomController.dispose();
      row.prixController.dispose();
      row.quantiteController.dispose();
    }
    super.dispose();
  }

  // somme totale
  void _updateTotal() {
    if (_isManualTotal) return;

    double total = 0;

    for (final row in _rows) {
      final prix = double.tryParse(row.prixController.text) ?? 0;
      final quantite = double.tryParse(row.quantiteController.text) ?? 0;
      total += prix * quantite;
    }

    final totalText = total.toStringAsFixed(0);
    if (_sommeController.text != totalText) {
      _sommeController.value = TextEditingValue(
        text: totalText,
        selection: TextSelection.collapsed(offset: totalText.length),
      );
    }
  }

  // funct ajout produit auto
  Future<void> _loadProduits() async {
    final snapshot = await _produit.get();
    final produits = <String>[];
    final prixParProduit = <String, dynamic>{};
  
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final nomProduit = data?['nom']?.toString();
      final prix = data?['prix'];
     
      if (nomProduit != null && nomProduit.isNotEmpty) {
        produits.add(nomProduit);
        prixParProduit[nomProduit] = prix ?? '';
       }
    }

    if (!mounted) return;

    setState(() {
      _produits
        ..clear()
        ..addAll(produits.toSet().toList()..sort());
      _produitPrix.clear();
      _produitPrix.addAll(prixParProduit);
     });
  }

  // date
  String _todayDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor:  Colors.blue.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: Text('Calcul Rec'),
        actions: [
          IconButton(onPressed: (){
            showDialog(context: context, builder: (context) => AlertDialog(
              title: Text('les formules'),
              content: Column(children: [
               Text(' 1 vetement a 500 fcfa',
               style: TextStyle(fontSize: 18,
               fontWeight: FontWeight.bold),
               ),
               Text(' 5 vetements a 2000 fcfa ',
               style: TextStyle(fontSize: 18,
               fontWeight: FontWeight.bold),
               ),
               Text(' 10 vetements a 3500 fcfa',
               style: TextStyle(fontSize: 18,
               fontWeight: FontWeight.bold),
               ),
               Text(' 15 vetements a 5500 fcfa',
               style: TextStyle(fontSize: 18,
               fontWeight: FontWeight.bold),
               )
              ],),
            ));
          }, icon: Icon(Icons.list_alt_outlined, color: Colors.white)),
          IconButton(
            onPressed: () {
              String display = '';
              double? firstValue;
              String? operator;

              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    void onNum(String v) {
                      setState(() => display += v);
                    }

                    void onOp(String op) {
                      firstValue = double.tryParse(display) ?? 0;
                      operator = op;
                      setState(() => display = '');
                    }

                    void onClear() {
                      firstValue = null;
                      operator = null;
                      setState(() => display = '');
                    }

                    void onBack() {
                      if (display.isNotEmpty) {
                        setState(() => display = display.substring(0, display.length - 1));
                      }
                    }

                    void onEquals() {
                      final second = double.tryParse(display) ?? 0;
                      double result = 0;
                      if (operator == '+') result = (firstValue ?? 0) + second;
                      else if (operator == '-') result = (firstValue ?? 0) - second;
                      else if (operator == '×' || operator == '*') result = (firstValue ?? 0) * second;
                      else if (operator == '÷' || operator == '/') result = (second == 0) ? 0 : (firstValue ?? 0) / second;

                      final textResult = (result % 1 == 0) ? result.toStringAsFixed(0) : result.toStringAsFixed(2);
                      setState(() => display = textResult);
                      _sommeController.text = textResult;
                      // 
                      _isManualTotal = true;
                    }

                    final buttons = [
                      '7', '8', '9', '÷',
                      '4', '5', '6', '×',
                      '1', '2', '3', '-',
                      '0', '.', '=', '+',
                    ];

                    return AlertDialog(
                      title: const Text('Calculatrice'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            alignment: Alignment.centerRight,
                            child: Text(display.isEmpty ? '0' : display, style: const TextStyle(fontSize: 28)),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 320,
                            width: 320,
                            child: GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                for (final b in buttons)
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (b == '=') return onEquals();
                                        if (b == '÷' || b == '×' || b == '+' || b == '-') return onOp(b);
                                        if (b == '.') {
                                          if (!display.contains('.')) onNum('.');
                                          return;
                                        }
                                        onNum(b);
                                      },
                                      child: Text(b, style: const TextStyle(fontSize: 20)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(onPressed: onClear, child: const Text('C')),
                              OutlinedButton(onPressed: onBack, child: const Icon(Icons.backspace)),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.calculate_outlined, color: Colors.white),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveInvoice,
              // icon: const Icon(Icons.save),
              // label: const Text('Enregistrer'),
              child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          setState(() {
            // ajouter un ligne
            _rows.add(ProductRowData());
          });
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        children: [
          // Section Total Montant
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Montant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _sommeController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    _isManualTotal = true;
                  },
                  decoration: InputDecoration(
                    hintText: 'somme',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Row(
                    children: [
                    Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nomcltController,
                      decoration: InputDecoration(
                        hintText: 'Nom du client',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                       validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'nom est requis';
                    return null;
                  },
                    ),
                  ),
                  SizedBox(width: 4),
                   Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _numeroController,
                      decoration: InputDecoration(
                        hintText: 'Numero',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ), 
                    ),
                  ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
               Row(
                children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: selectedser,
                      isExpanded: true,
                      hint: Text('service'),

                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'lavage',
                          child: Text('lavage'),
                        ),
                        DropdownMenuItem(
                          value: 'repassage',
                          child: Text('repassage'),
                        ),
                        DropdownMenuItem(
                          value: 'traitement',
                          child: Text('traitement'),
                        ),
                        
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          selectedser = value ?? 'lavage';
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  flex: 3,
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
                 SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                      controller: _numfactController,
                      readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'N.fact',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
               ]),
              ],
            ),
          ),
          // Lignes de produits dynamiques
          ..._rows.asMap().entries.map((entry) {
            return _buildProductRow(entry.key);
          }),
        ],
      ),
    );
  }

  //  config pro auto
  Widget _buildProductRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return _produits.where(
                    (produit) => produit.toLowerCase().contains(
                      value.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      textEditingController.text = row.nomController.text;
                      textEditingController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: textEditingController.text.length),
                      );

                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onSubmitted: (_) => onFieldSubmitted(),
                        decoration: InputDecoration(
                          hintText: 'Nom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      );
                    },
                onSelected: (String selection) {
                  setState(() {
                    row.selectedProduit = selection;
                    row.nomController.text = selection;
                    final prix = _produitPrix[selection];
                    row.prixController.text = prix?.toString() ?? '';
                    
                  
                    _updateTotal();
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.prixController,
              decoration: InputDecoration(
                hintText: 'prix unitaire',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.quantiteController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateTotal(),
              decoration: InputDecoration(
                hintText: 'Quantite',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}