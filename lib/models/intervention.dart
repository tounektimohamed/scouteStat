import 'package:cloud_firestore/cloud_firestore.dart';

class Intervention {
  final String id;
  final String? userId;
  final String? volontaire;
  final DateTime? date;
  final double? heuresTravail;
  final String? refugies;
  final String? carteNumero;
  final String? telephone;
  final String? genre;
  final String? ageCategory;
  final String? pays;
  final String? typeIntervention;
  final int? nbActesMedicaux;
  final String? typeEtablissement;
  final String? etablissementMedical;
  final String? secteur;
  final double? montantPaye;
  final DateTime? prochainRdv;
  final String? rdvEtablissement;
  final String? suiviMedicament;
  final String? description;
  final String? remarques;
  final DateTime? createdAt;

  Intervention({
    required this.id,
    this.userId,
    this.volontaire,
    this.date,
    this.heuresTravail,
    this.refugies,
    this.carteNumero,
    this.telephone,
    this.genre,
    this.ageCategory,
    this.pays,
    this.typeIntervention,
    this.nbActesMedicaux,
    this.typeEtablissement,
    this.etablissementMedical,
    this.secteur,
    this.montantPaye,
    this.prochainRdv,
    this.rdvEtablissement,
    this.suiviMedicament,
    this.description,
    this.remarques,
    this.createdAt,
  });

  factory Intervention.fromMap(Map<String, dynamic> data, String id) {
    return Intervention(
      id: id,
      userId: data['userId'] as String?,
      volontaire: data['volontaire'] as String?,
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      heuresTravail: data['heuresTravail'] != null 
          ? (data['heuresTravail'] as num).toDouble() 
          : null,
      refugies: data['refugies'] as String?,
      carteNumero: data['carteNumero'] as String?,
      telephone: data['telephone'] as String?,
      genre: data['genre'] as String?,
      ageCategory: data['ageCategory'] as String?,
      pays: data['pays'] as String?,
      typeIntervention: data['typeIntervention'] as String?,
      nbActesMedicaux: data['nbActesMedicaux'] as int?,
      typeEtablissement: data['typeEtablissement'] as String?,
      etablissementMedical: data['etablissementMedical'] as String?,
      secteur: data['secteur'] as String?,
      montantPaye: data['montantPaye'] != null 
          ? (data['montantPaye'] as num).toDouble() 
          : null,
      prochainRdv: data['prochainRdv'] != null 
          ? (data['prochainRdv'] as Timestamp).toDate() 
          : null,
      rdvEtablissement: data['rdvEtablissement'] as String?,
      suiviMedicament: data['suiviMedicament'] as String?,
      description: data['description'] as String?,
      remarques: data['remarques'] as String?,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'volontaire': volontaire,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'heuresTravail': heuresTravail,
      'refugies': refugies,
      'carteNumero': carteNumero,
      'telephone': telephone,
      'genre': genre,
      'ageCategory': ageCategory,
      'pays': pays,
      'typeIntervention': typeIntervention,
      'nbActesMedicaux': nbActesMedicaux,
      'typeEtablissement': typeEtablissement,
      'etablissementMedical': etablissementMedical,
      'secteur': secteur,
      'montantPaye': montantPaye,
      'prochainRdv': prochainRdv != null ? Timestamp.fromDate(prochainRdv!) : null,
      'rdvEtablissement': rdvEtablissement,
      'suiviMedicament': suiviMedicament,
      'description': description,
      'remarques': remarques,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Intervention copyWith({
    String? id,
    String? userId,
    String? volontaire,
    DateTime? date,
    double? heuresTravail,
    String? refugies,
    String? carteNumero,
    String? telephone,
    String? genre,
    String? ageCategory,
    String? pays,
    String? typeIntervention,
    int? nbActesMedicaux,
    String? typeEtablissement,
    String? etablissementMedical,
    String? secteur,
    double? montantPaye,
    DateTime? prochainRdv,
    String? rdvEtablissement,
    String? suiviMedicament,
    String? description,
    String? remarques,
    DateTime? createdAt,
  }) {
    return Intervention(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      volontaire: volontaire ?? this.volontaire,
      date: date ?? this.date,
      heuresTravail: heuresTravail ?? this.heuresTravail,
      refugies: refugies ?? this.refugies,
      carteNumero: carteNumero ?? this.carteNumero,
      telephone: telephone ?? this.telephone,
      genre: genre ?? this.genre,
      ageCategory: ageCategory ?? this.ageCategory,
      pays: pays ?? this.pays,
      typeIntervention: typeIntervention ?? this.typeIntervention,
      nbActesMedicaux: nbActesMedicaux ?? this.nbActesMedicaux,
      typeEtablissement: typeEtablissement ?? this.typeEtablissement,
      etablissementMedical: etablissementMedical ?? this.etablissementMedical,
      secteur: secteur ?? this.secteur,
      montantPaye: montantPaye ?? this.montantPaye,
      prochainRdv: prochainRdv ?? this.prochainRdv,
      rdvEtablissement: rdvEtablissement ?? this.rdvEtablissement,
      suiviMedicament: suiviMedicament ?? this.suiviMedicament,
      description: description ?? this.description,
      remarques: remarques ?? this.remarques,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}