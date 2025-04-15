import 'package:cloud_firestore/cloud_firestore.dart';

class Intervention {
  final String id;
  final String? userId;
  final String? nomVolontaire;
  final String? sexeVolontaire;
  final DateTime? dateIntervention;
  final double? heuresTravail;
  final String? typeIntervention;
  final String? etablissement;
  final String? typeEtablissement;
  final String? secteur;
  final String? sexeRefugie;
  final String? ageRefugie;
  final String? region;
  final DateTime? createdAt;

  Intervention({
    required this.id,
    this.userId,
    this.nomVolontaire,
    this.sexeVolontaire,
    this.dateIntervention,
    this.heuresTravail,
    this.typeIntervention,
    this.etablissement,
    this.typeEtablissement,
    this.secteur,
    this.sexeRefugie,
    this.ageRefugie,
    this.region,
    this.createdAt,
  });

  factory Intervention.fromMap(Map<String, dynamic> data, String id) {
    return Intervention(
      id: id,
      userId: data['userId'] as String?,
      nomVolontaire: data['nomVolontaire'] as String?,
      sexeVolontaire: data['sexeVolontaire'] as String?,
      dateIntervention: data['dateIntervention'] != null
          ? (data['dateIntervention'] as Timestamp).toDate()
          : null,
      heuresTravail: data['heuresTravail'] != null
          ? (data['heuresTravail'] as num).toDouble()
          : null,
      typeIntervention: data['typeIntervention'] as String?,
      etablissement: data['etablissement'] as String?,
      typeEtablissement: data['typeEtablissement'] as String?,
      secteur: data['secteur'] as String?,
      sexeRefugie: data['sexeRefugie'] as String?,
      ageRefugie: data['ageRefugie'] as String?,
      region: data['region'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nomVolontaire': nomVolontaire,
      'sexeVolontaire': sexeVolontaire,
      'dateIntervention': dateIntervention != null
          ? Timestamp.fromDate(dateIntervention!)
          : null,
      'heuresTravail': heuresTravail,
      'typeIntervention': typeIntervention,
      'etablissement': etablissement,
      'typeEtablissement': typeEtablissement,
      'secteur': secteur,
      'sexeRefugie': sexeRefugie,
      'ageRefugie': ageRefugie,
      'region': region,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Intervention copyWith({
    String? id,
    String? userId,
    String? nomVolontaire,
    String? sexeVolontaire,
    DateTime? dateIntervention,
    double? heuresTravail,
    String? typeIntervention,
    String? etablissement,
    String? typeEtablissement,
    String? secteur,
    String? sexeRefugie,
    String? ageRefugie,
    String? region,
    DateTime? createdAt,
  }) {
    return Intervention(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nomVolontaire: nomVolontaire ?? this.nomVolontaire,
      sexeVolontaire: sexeVolontaire ?? this.sexeVolontaire,
      dateIntervention: dateIntervention ?? this.dateIntervention,
      heuresTravail: heuresTravail ?? this.heuresTravail,
      typeIntervention: typeIntervention ?? this.typeIntervention,
      etablissement: etablissement ?? this.etablissement,
      typeEtablissement: typeEtablissement ?? this.typeEtablissement,
      secteur: secteur ?? this.secteur,
      sexeRefugie: sexeRefugie ?? this.sexeRefugie,
      ageRefugie: ageRefugie ?? this.ageRefugie,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Intervention{id: $id, userId: $userId, nomVolontaire: $nomVolontaire, sexeVolontaire: $sexeVolontaire, dateIntervention: $dateIntervention, heuresTravail: $heuresTravail, typeIntervention: $typeIntervention, etablissement: $etablissement, typeEtablissement: $typeEtablissement, secteur: $secteur, sexeRefugie: $sexeRefugie, ageRefugie: $ageRefugie, region: $region, createdAt: $createdAt}';
  }
}
