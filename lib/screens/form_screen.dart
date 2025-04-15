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
  final _nomController = TextEditingController();
  final _heuresController = TextEditingController();
  final _etablissementController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userName;
  bool _isSubmitting = false;

  // Données statiques
  final List<String> _typesIntervention = [
    'Analyse médicale',
    'Médicament',
    'Radiologie',
    'Urgence',
    'Consultation',
    'Frais admission'
  ];
  final List<String> _regions = ['Sud', 'Nord'];
  final List<String> _sexes = ['Homme', 'Femme'];
  final List<String> _agesRefugies = [
    '-5 ans',
    'de 5 à 10 ans',
    'de 10 à 18 ans',
    '+18 à 30 ans',
    '+30 à 50 ans',
    '+50 ans'
  ];
  final List<String> _typesEtablissement = [
    'Primary Healthcare',
    'Secondaire',
    'Tertiary'
  ];
  final List<String> _secteurs = ['Privé', 'Public'];

  // Variables d'état
  String? _sexeVolontaire;
  DateTime? _dateIntervention;
  String? _sexeRefugie;
  String? _typeIntervention;
  String? _region;
  String? _ageRefugie;
  String? _typeEtablissement;
  String? _secteur;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
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

          // Si le nom n'existe pas dans Firestore
          if (_userName == null || _userName!.isEmpty) {
            _userName = 'Utilisateur ${user.uid.substring(0, 6)}';
          }

          _nomController.text = _userName!;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Utilisateur inconnu';
          _nomController.text = _userName!; // Ajout du ! pour résoudre l'erreur
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nouvelle Intervention',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Informations Volontaire
              _buildSectionHeader(
                icon: Icons.person_outline,
                title: 'Informations du Volontaire',
                color: Colors.blue,
              ),
              SizedBox(height: 12),
              _buildTextFormField(
                controller: _nomController,
                label: 'Nom complet',
                icon: Icons.badge_outlined,
                validator: null,
                readOnly: true,
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _sexeVolontaire,
                items: _sexes,
                label: 'Sexe du volontaire',
                icon: Icons.wc_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) =>
                    setState(() => _sexeVolontaire = newValue),
              ),

              // Section Détails Intervention
              SizedBox(height: 24),
              _buildSectionHeader(
                icon: Icons.medical_services_outlined,
                title: 'Détails de l\'Intervention',
                color: Colors.green,
              ),
              SizedBox(height: 12),
              _buildDateTimeField(
                label: 'Date de l\'intervention',
                icon: Icons.calendar_today_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _heuresController,
                label: 'Heures de travail',
                icon: Icons.access_time_outlined,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Ce champ est obligatoire';
                  if (double.tryParse(value) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _typeIntervention,
                items: _typesIntervention,
                label: 'Type d\'intervention',
                icon: Icons.local_hospital_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) =>
                    setState(() => _typeIntervention = newValue),
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _typeEtablissement,
                items: _typesEtablissement,
                label: 'Type d\'établissement',
                icon: Icons.medical_services_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) =>
                    setState(() => _typeEtablissement = newValue),
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _secteur,
                items: _secteurs,
                label: 'Secteur',
                icon: Icons.business_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) => setState(() => _secteur = newValue),
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _etablissementController,
                label: 'Établissement médical',
                icon: Icons.local_hospital_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est obligatoire' : null,
              ),

              // Section Informations Bénéficiaire
              SizedBox(height: 24),
              _buildSectionHeader(
                icon: Icons.people_outline,
                title: 'Informations du Bénéficiaire',
                color: Colors.orange,
              ),
              SizedBox(height: 12),
              _buildDropdownFormField(
                value: _sexeRefugie,
                items: _sexes,
                label: 'Sexe du bénéficiaire',
                icon: Icons.wc_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) =>
                    setState(() => _sexeRefugie = newValue),
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _ageRefugie,
                items: _agesRefugies,
                label: 'Âge du bénéficiaire',
                icon: Icons.cake_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) => setState(() => _ageRefugie = newValue),
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _region,
                items: _regions,
                label: 'Région',
                icon: Icons.map_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) => setState(() => _region = newValue),
              ),

              // Bouton de soumission
              SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.save_outlined, size: 24),
                  label: Text(
                    'ENREGISTRER L\'INTERVENTION',
                    style: TextStyle(fontSize: 16, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
      ),
      validator: validator,
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required IconData icon,
    required String? Function(DateTime?)? validator,
  }) {
    return DateTimeField(
      format: DateFormat('yyyy-MM-dd'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
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
                  primary: Theme.of(context).primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        setState(() => _dateIntervention = date);
        return date;
      },
      validator: validator,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aide'),
        content: Text(
          'Remplissez tous les champs obligatoires pour enregistrer une nouvelle intervention. '
          'Les champs marqués d\'un astérisque (*) sont obligatoires.',
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dateIntervention == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une date valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vous devez être connecté pour soumettre une intervention'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Assure que le nom est toujours rempli
      if (_nomController.text.isEmpty && _userName != null) {
        _nomController.text = _userName!;
      }

      await FirebaseFirestore.instance.collection('interventions').add({
        'userId': user.uid,
        'nomVolontaire': _nomController.text.isNotEmpty
            ? _nomController.text
            : _userName ?? 'Utilisateur inconnu',
        'sexeVolontaire': _sexeVolontaire,
        'dateIntervention': Timestamp.fromDate(_dateIntervention!),
        'heuresTravail': double.tryParse(_heuresController.text) ?? 0.0,
        'typeIntervention': _typeIntervention,
        'etablissement': _etablissementController.text,
        'typeEtablissement': _typeEtablissement,
        'secteur': _secteur,
        'sexeRefugie': _sexeRefugie,
        'ageRefugie': _ageRefugie,
        'region': _region,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Intervention enregistrée avec succès!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Réinitialisation du formulaire
      _formKey.currentState?.reset();
      setState(() {
        _sexeVolontaire = null;
        _dateIntervention = null;
        _sexeRefugie = null;
        _typeIntervention = null;
        _region = null;
        _ageRefugie = null;
        _typeEtablissement = null;
        _secteur = null;
        _heuresController.clear();
        _etablissementController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _heuresController.dispose();
    _etablissementController.dispose();
    super.dispose();
  }
}
