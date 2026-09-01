import 'package:flutter/material.dart';
import 'package:pressing_opropre/view/admin/rapport_resultats.dart';


class Rapann extends StatelessWidget {
	const Rapann({super.key, required this.year});

	final int year;

	@override
	Widget build(BuildContext context) {
		return RapportResultats(
			title: 'Rapport annuel',
			description: 'Recettes de l’année $year',
			filterDate: (value) => value != null && value.year == year,
		);
	}
}
