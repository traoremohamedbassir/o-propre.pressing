import 'package:flutter/material.dart';
import 'package:pressing_opropre/view/admin/rapport_resultats.dart';

class Rapmois extends StatelessWidget {
	const Rapmois({super.key, required this.month, required this.year});

	final int month;
	final int year;

	@override
	Widget build(BuildContext context) {
		return RapportResultats(
      
			title: 'Rapport mensuel',
			description: 'Recettes du mois $month/$year',
			filterDate: (value) => value != null && value.year == year && value.month == month,
		);
	}
}
