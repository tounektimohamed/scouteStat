class Intervention {
  String? id;
  final String nomVolontaire;
  final String sexeVolontaire;
  final DateTime dateIntervention;
  final double heuresTravail;
  final String sexeRefugie;
  final String typeIntervention;
  final String etablissementMedical;
  final String region;

  Intervention({
    this.id,
    required this.nomVolontaire,
    required this.sexeVolontaire,
    required this.dateIntervention,
    required this.heuresTravail,
    required this.sexeRefugie,
    required this.typeIntervention,
    required this.etablissementMedical,
    required this.region,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomVolontaire': nomVolontaire,
      'sexeVolontaire': sexeVolontaire,
      'dateIntervention': dateIntervention.toIso8601String(),
      'heuresTravail': heuresTravail,
      'sexeRefugie': sexeRefugie,
      'typeIntervention': typeIntervention,
      'etablissementMedical': etablissementMedical,
      'region': region,
    };
  }

  static Intervention fromMap(Map<String, dynamic> map, String id) {
    return Intervention(
      id: id,
      nomVolontaire: map['nomVolontaire'],
      sexeVolontaire: map['sexeVolontaire'],
      dateIntervention: DateTime.parse(map['dateIntervention']),
      heuresTravail: map['heuresTravail'].toDouble(),
      sexeRefugie: map['sexeRefugie'],
      typeIntervention: map['typeIntervention'],
      etablissementMedical: map['etablissementMedical'],
      region: map['region'],
    );
  }
}