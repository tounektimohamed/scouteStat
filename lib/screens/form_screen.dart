import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volontaireController = TextEditingController();
  final _dureeController = TextEditingController();
  final _heuresController = TextEditingController();
  final _refugiesController = TextEditingController();
  final _carteController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _etablissementController = TextEditingController();
  final _montantController = TextEditingController();
  final _medicamentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remarquesController = TextEditingController();
  final _paysController = TextEditingController();
  final _nbActesController = TextEditingController();
  final _rdvEtablissementController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userName;
  bool _isSubmitting = false;

  // Medical specialties list

final List<String> _typesIntervention = [
  'Consultation Médicale Générale',
  'Urgences Médicales',
  'Soins Infirmiers',
  'Petite Chirurgie',
  'Vaccination',
  'Maternité (Accouchement)',
  'Pédiatrie',
  'Cardiologie',
  'Diabétologie',
  'Dermatologie',
  'Ophtalmologie',
  'ORL',
  'Psychiatrie',
  'Radiologie/Imagerie',
  'Analyses Médicales',
  'Chirurgie Générale',
  'Soins Dentaires',
  'Kinésithérapie',
  'Médecine du Travail',
  'Achat Médicaments',  // Nouveau
  'Frais d\'Admission',  // Nouveau
  'Autre'
];

final List<String> _typesEtablissement = [
  'Centre de Santé de Base (CSB)',
  'Hôpital Régional',
  'Hôpital Universitaire (CHU)',
  'Clinique Privée',
  'Centre Spécialisé',
  'Pharmacie',
  'Laboratoire d\'Analyses',
  'Centre d\'Hémodialyse',
  'Autre'
];


 final List<String> _secteurs = ['Privé', 'Public'];
  final List<String> _genres = ['Homme', 'Femme'];
  final List<String> _ageCategories = ['Adulte', 'Enfant'];

  // Variables d'état
  DateTime? _dateIntervention;
  DateTime? _prochainRdv;
  String? _genre;
  String? _typeIntervention;
  String? _typeEtablissement;
  String? _secteur;
  String? _ageCategory;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName().then((_) {
      if (_userName != null) {
        _volontaireController.text = _userName!;
      }
    });
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userName = doc.data()?['name']?.trim();
          if (_userName == null || _userName!.isEmpty) {
            _userName = user.email?.split('@').first ?? 'Utilisateur';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Utilisateur';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Intervention Médicale'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Basic Information
              _buildSectionHeader(
                'Informations de base',
                icon: Icons.info_outline,
                color: Colors.blue,
              ),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _volontaireController,
                        decoration: InputDecoration(
                          labelText: 'Volontaire',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        readOnly: true,
                      ),
                      SizedBox(height: 16),
                      _buildDateTimeField(
                        label: 'Date',
                        onChanged: (date) => _dateIntervention = date,
                      ),
                      SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _heuresController,
                        label: 'Heures de travail',
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Section 2: Patient Information
              _buildSectionHeader(
                'Informations du patient',
                icon: Icons.personal_injury,
                color: Colors.green,
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextFormField(
                        controller: _refugiesController,
                        label: 'Réfugiés',
                      ),
                      _buildTextFormField(
                        controller: _carteController,
                        label: 'N° carte',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextFormField(
                        controller: _telephoneController,
                        label: 'Numéro téléphone',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildDropdownFormField(
                        value: _genre,
                        items: _genres,
                        label: 'Genre',
                        onChanged: (value) => setState(() => _genre = value),
                      ),
                      _buildDropdownFormField(
                        value: _ageCategory,
                        items: _ageCategories,
                        label: 'Catégorie d\'âge',
                        onChanged: (value) => setState(() => _ageCategory = value),
                      ),
                      _buildTextFormField(
                        controller: _paysController,
                        label: 'Pays',
                      ),
                    ],
                  ),
                ),
              ),

              // Section 3: Medical Information
              _buildSectionHeader(
                'Informations médicales',
                icon: Icons.medical_services,
                color: Colors.red,
              ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDropdownFormField(
                        value: _typeIntervention,
                        items: _typesIntervention,
                        label: 'Type d\'intervention',
                        onChanged: (value) => setState(() => _typeIntervention = value),
                      ),
                      _buildTextFormField(
                        controller: _nbActesController,
                        label: 'Nombre d\'actes médicaux',
                        keyboardType: TextInputType.number,
                      ),
                      _buildDropdownFormField(
                        value: _typeEtablissement,
                        items: _typesEtablissement,
                        label: 'Type d\'établissement',
                        onChanged: (value) => setState(() => _typeEtablissement = value),
                      ),
                      _buildTextFormField(
                        controller: _etablissementController,
                        label: 'Nom de l\'établissement',
                      ),
                      _buildDropdownFormField(
                        value: _secteur,
                        items: _secteurs,
                        label: 'Secteur',
                        onChanged: (value) => setState(() => _secteur = value),
                      ),
                      _buildTextFormField(
                        controller: _montantController,
                        label: 'Montant payé',
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      _buildDateTimeField(
                        label: 'Prochain rendez-vous',
                        onChanged: (date) => _prochainRdv = date,
                      ),
                      _buildTextFormField(
                        controller: _rdvEtablissementController,
                        label: 'Établissement pour le RDV',
                      ),
                      _buildTextFormField(
                        controller: _medicamentController,
                        label: 'Suivi médicament',
                        maxLines: 3,
                      ),
                      _buildTextFormField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                      ),
                      _buildTextFormField(
                        controller: _remarquesController,
                        label: 'Remarques',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: color ?? Theme.of(context).primaryColor),
          if (icon != null) SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        onChanged: onChanged,
       // validator: (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null,
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        //validator: (value) => value == null ? 'Ce champ est requis' : null,
        isExpanded: true,
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required Function(DateTime?) onChanged,
  }) {
    return DateTimeField(
      format: DateFormat('yyyy-MM-dd'),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: Icon(Icons.calendar_today, size: 20),
      ),
      onShowPicker: (context, currentValue) async {
        final date = await showDatePicker(
          context: context,
          initialDate: currentValue ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade600,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onChanged(date);
        }
        return date;
      },
      //validator: (value) => value == null ? 'Ce champ est requis' : null,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('interventions').add({
        'userId': user.uid,
        'volontaire': _volontaireController.text,
        'date': _dateIntervention,
        'heuresTravail': double.tryParse(_heuresController.text),
        'refugies': _refugiesController.text,
        'carteNumero': _carteController.text,
        'telephone': _telephoneController.text,
        'genre': _genre,
        'ageCategory': _ageCategory,
        'pays': _paysController.text,
        'typeIntervention': _typeIntervention,
        'nbActesMedicaux': int.tryParse(_nbActesController.text),
        'typeEtablissement': _typeEtablissement,
        'etablissementMedical': _etablissementController.text,
        'secteur': _secteur,
        'montantPaye': double.tryParse(_montantController.text),
        'prochainRdv': _prochainRdv,
        'rdvEtablissement': _rdvEtablissementController.text,
        'suiviMedicament': _medicamentController.text,
        'description': _descriptionController.text,
        'remarques': _remarquesController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Intervention enregistrée avec succès!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState?.reset();
      setState(() {
        _dateIntervention = null;
        _prochainRdv = null;
        _genre = null;
        _ageCategory = null;
        _typeIntervention = null;
        _typeEtablissement = null;
        _secteur = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _volontaireController.dispose();
    _dureeController.dispose();
    _heuresController.dispose();
    _refugiesController.dispose();
    _carteController.dispose();
    _telephoneController.dispose();
    _etablissementController.dispose();
    _montantController.dispose();
    _medicamentController.dispose();
    _descriptionController.dispose();
    _remarquesController.dispose();
    _paysController.dispose();
    _nbActesController.dispose();
    _rdvEtablissementController.dispose();
    super.dispose();
  }
}