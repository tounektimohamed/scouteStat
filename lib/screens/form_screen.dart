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

  // Variables d'état
  String? _sexeVolontaire;
  DateTime? _dateIntervention;
  String? _sexeRefugie;
  String? _typeIntervention;
  String? _region;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est obligatoire' : null,
              ),
              SizedBox(height: 16),
              _buildDropdownFormField(
                value: _sexeVolontaire,
                items: _sexes,
                label: 'Sexe du volontaire',
                icon: Icons.wc_outlined,
                validator: (value) =>
                    value == null ? 'Ce champ est obligatoire' : null,
                onChanged: (newValue) => setState(() => _sexeVolontaire = newValue),
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
                onChanged: (newValue) => setState(() => _typeIntervention = newValue),
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
                onChanged: (newValue) => setState(() => _sexeRefugie = newValue),
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
                  icon: Icon(Icons.save_outlined, size: 24),
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
                  onPressed: _submitForm,
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
    if (_formKey.currentState!.validate()) {
      try {
        // Votre logique d'enregistrement ici
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Intervention enregistrée avec succès'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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