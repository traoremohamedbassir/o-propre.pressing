import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pressing_opropre/Controller/auth.dart';
import 'package:pressing_opropre/connexion/login.dart';
import 'package:pressing_opropre/view/admin/caisse.dart';
import 'package:pressing_opropre/view/admin/produit.dart';
import 'package:pressing_opropre/view/admin/rapport.dart';
import 'package:pressing_opropre/view/admin/recette.dart';
import 'package:pressing_opropre/view/constant/drawer.dart';
import 'package:fl_chart/fl_chart.dart';

AuthService _authService = AuthService();
class Homeadm extends StatefulWidget {
  const Homeadm({super.key});

  @override
  State<Homeadm> createState() => _HomeadmState();
}

class _HomeadmState extends State<Homeadm> {
  String _userName = '';
  double _todayRevenue = 0;
  final Map<int, double> _monthlyTotals = {for (var i = 1; i <= 12; i++) i: 0.0};
  // final CollectionReference _stocks = FirebaseFirestore.instance.collection(
  //   'stocks',
  // );
  

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Produits',
      'image': 'lib/assets/produit/produit.PNG',
      'route': const Produit(),
    },
    {
      'title': 'Recettes',
      'image': 'lib/assets/recette/recette.PNG',
      'route': const Recette(),
    },
    {
      'title': 'Caisses',
      'image': 'lib/assets/caisse/caisse.PNG',
      'route': const Caisse(),
    },
    {
      'title': 'Rapports',
      'image': 'lib/assets/rapport/rapport1.PNG',
      'route': const Rapport(),
    },
  ];
// use
  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadRecettesSummary();
  }
// use
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

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(text);
  }

  Future<void> _loadRecettesSummary() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('recettes').get();
      final now = DateTime.now();
      double today = 0.0;
      final totals = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final montantRaw = data['montant'];
        double montant = 0.0;
        if (montantRaw is num) montant = montantRaw.toDouble();
        else if (montantRaw is String) montant = double.tryParse(montantRaw) ?? 0.0;

        DateTime? date = _parseDate(data['date']);
        if (date == null && data['created_at'] != null) {
          final ca = data['created_at'];
          if (ca is Timestamp) date = ca.toDate();
        }

        if (date != null && date.year == now.year) {
          totals[date.month] = (totals[date.month] ?? 0) + montant;
          if (date.day == now.day && date.month == now.month && date.year == now.year) {
            today += montant;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _todayRevenue = today;
        _monthlyTotals.clear();
        _monthlyTotals.addAll(totals);
      });
    } catch (e) {
      // ignore errors silently for now
    }
  }

  String _formatCurrency(double v) {
    return '${v.toStringAsFixed(0)} FCFA';
  }
  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:  Colors.blue.shade100,
        appBar: AppBar(
          
          title: Text(
            ' $_userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 2,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: (){
                 _authService.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Login()),
                    );
              },
            ),
          ],
        ),
        drawer: const Drawers(),
        body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                          child: _StatCard(
                            title: 'Recette du jour',
                            value: _formatCurrency(_todayRevenue),
                            icon: Icons.monetization_on_outlined,
                            color: const Color(0xFF10B981),
                          ),
                        ),

                    
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Performance',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'annee',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: _MonthlyBarChart(monthlyTotals: _monthlyTotals),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Gestion rapide',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _BuildMenuCard(
                      title: item['title'],
                      image: item['image'],
                      route: item['route'],
                      index: index,
                    );
                  },
                ),
              ],
        ))
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}



class _BuildMenuCard extends StatelessWidget {
  final String title;
  final String image;
  final Widget route;
  final int index;

  const _BuildMenuCard({
    required this.title,
    required this.image,
    required this.route,
    required this.index,
  });

  BorderRadius _getRadius() {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(20));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(20));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(20));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(20));
      default:
        return BorderRadius.circular(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => route));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 244, 243, 243),
          borderRadius: _getRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black87.withOpacity(0.15),
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: _getRadius(),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final Map<int, double> monthlyTotals;

  const _MonthlyBarChart({required this.monthlyTotals});

  static const List<String> _months = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui', 'Jui', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
  ];

  @override
  Widget build(BuildContext context) {
    final maxValue = (monthlyTotals.values.fold<double>(0.0, (a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);
    final groups = List.generate(12, (i) {
      final month = i + 1;
      final value = monthlyTotals[month] ?? 0.0;
      return BarChartGroupData(
        x: month,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 14,
            borderRadius: BorderRadius.circular(6),
            color: Colors.blue.shade700,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue,
              color: Colors.blue.shade100,
            ),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxValue,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final monthIndex = group.x - 1;
              final label = monthIndex >= 0 && monthIndex < _months.length
              ? _months[monthIndex] : group.x.toString();
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(0)} FCFA',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt() - 1;
                final txt = (idx >= 0 && idx < _months.length) ? _months[idx] : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(txt, style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }
}
