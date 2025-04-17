import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intervention_stats/models/intervention.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _monthFormat = DateFormat('MMM yyyy');
  final DateFormat _dayFormat = DateFormat('dd/MM/yy');
  final DateFormat _exportDateFormat = DateFormat('yyyy-MM-dd');
  
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _userName; // Variable renommée pour être cohérente partout
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _userName = 'Utilisateur';
            _isLoadingUser = false;
          });
        }
        return;
      }

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
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Utilisateur';
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _exportToCSV(List<Intervention> interventions) async {
    if (_isLoadingUser) {
      await _loadCurrentUserName();
    }

    try {
      final csvData = <List<dynamic>>[
        [
          'Date', 'Volontaire', 'Heures', 'Patient', 'N° Carte', 'Téléphone',
          'Genre', 'Catégorie', 'Pays', 'Type Intervention', 'Nb Actes',
          'Type Établissement', 'Établissement', 'Secteur', 'Montant',
          'Prochain RDV', 'Établissement RDV', 'Médicaments', 'Description', 'Remarques'
        ],
        ...interventions.map((i) => [
          _exportDateFormat.format(i.date ?? DateTime.now()),
          i.volontaire?.isNotEmpty == true ? i.volontaire : _userName ?? 'Utilisateur', // Utilisation de _userName
          i.heuresTravail?.toStringAsFixed(1) ?? '0.0',
          i.refugies ?? '',
          i.carteNumero ?? '',
          i.telephone ?? '',
          i.genre ?? '',
          i.ageCategory ?? '',
          i.pays ?? '',
          i.typeIntervention ?? '',
          i.nbActesMedicaux?.toString() ?? '0',
          i.typeEtablissement ?? '',
          i.etablissementMedical ?? '',
          i.secteur ?? '',
          i.montantPaye?.toStringAsFixed(2) ?? '0.00',
          i.prochainRdv != null ? _exportDateFormat.format(i.prochainRdv!) : '',
          i.rdvEtablissement ?? '',
          i.suiviMedicament ?? '',
          i.description ?? '',
          i.remarques ?? ''
        ])
      ];

      final blob = html.Blob([const ListToCsvConverter().convert(csvData)], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement()
        ..href = url
        ..download = 'interventions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv'
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${interventions.length} interventions exportées'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'export: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          )
        );
      }
    }
  }
  // Nouvelle fonction pour exporter un rapport personnalisé
  Future<void> _exportCustomReport(List<Intervention> interventions) async {
    final fields = [
      'date', 'volontaire', 'refugies', 'typeIntervention', 'nbActesMedicaux',
      'montantPaye', 'etablissementMedical', 'secteur', 'description'
    ];

    final selectedFields = await showDialog<List<String>>(
      context: context,
      builder: (context) => _CustomReportDialog(fields: fields),
    );

    if (selectedFields == null || selectedFields.isEmpty) return;

    try {
      final headers = selectedFields.map((field) {
        switch (field) {
          case 'date': return 'Date';
          case 'volontaire': return 'Volontaire';
          case 'refugies': return 'Patient';
          case 'typeIntervention': return 'Type Intervention';
          case 'nbActesMedicaux': return 'Nb Actes';
          case 'montantPaye': return 'Montant';
          case 'etablissementMedical': return 'Établissement';
          case 'secteur': return 'Secteur';
          case 'description': return 'Description';
          default: return field;
        }
      }).toList();

      final csvData = <List<dynamic>>[
        headers,
        ...interventions.map((i) => selectedFields.map((field) {
          switch (field) {
            case 'date': 
              return _exportDateFormat.format(i.date ?? DateTime.now());
            case 'volontaire': 
              return i.volontaire ?? _userName ?? 'Utilisateur';
            case 'refugies': return i.refugies ?? '';
            case 'typeIntervention': return i.typeIntervention ?? '';
            case 'nbActesMedicaux': return i.nbActesMedicaux?.toString() ?? '0';
            case 'montantPaye': return i.montantPaye?.toStringAsFixed(2) ?? '0.00';
            case 'etablissementMedical': return i.etablissementMedical ?? '';
            case 'secteur': return i.secteur ?? '';
            case 'description': return i.description ?? '';
            default: return i.toMap()[field]?.toString() ?? '';
          }
        }).toList())
      ];

      final blob = html.Blob([const ListToCsvConverter().convert(csvData)], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement()
        ..href = url
        ..download = 'rapport_personnalise_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv'
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport personnalisé exporté (${interventions.length} interventions)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'export: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        )
      );
    }
  }


  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'custom';
      });
    }
  }

  List<Intervention> _applyFilters(List<Intervention> interventions) {
    if (_selectedFilter == 'all') return interventions;
    
    DateTime now = DateTime.now();
    DateTime filterDate;

    switch (_selectedFilter) {
      case 'week':
        filterDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        filterDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'quarter':
        filterDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        filterDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'custom':
        return interventions.where((i) =>
          i.date != null &&
          i.date!.isAfter(_startDate!) &&
          i.date!.isBefore(_endDate!.add(const Duration(days: 1)))
        ).toList();
      default:
        return interventions;
    }

    return interventions.where((i) => i.date != null && i.date!.isAfter(filterDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Médical'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, size: 28),
            tooltip: 'Filtrer',
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 28),
            tooltip: 'Exporter',
            onPressed: () async {
              final snapshot = await _db.collection('interventions').get();
              final interventions = snapshot.docs
                .map((doc) => Intervention.fromMap(doc.data()!, doc.id))
                .toList();
              _exportToCSV(interventions);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('interventions').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final interventions = snapshot.data!.docs
              .map((doc) => Intervention.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

            final filteredInterventions = _applyFilters(interventions);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCards(filteredInterventions),
                  const SizedBox(height: 24),
                  _buildTypeInterventionChart(filteredInterventions),
                  const SizedBox(height: 24),
                  _buildPatientCharts(filteredInterventions),
                  const SizedBox(height: 24),
                  _buildTrendCharts(filteredInterventions),
                  const SizedBox(height: 24),
                  _buildRecentInterventions(filteredInterventions),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Intervention> interventions) {
    final metrics = _calculateMetrics(interventions);
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMetricCard(
          title: 'Interventions',
          value: metrics['count'].toString(),
          icon: Icons.medical_services,
          color: Colors.blue.shade600,
        ),
        _buildMetricCard(
          title: 'Actes Médicaux',
          value: metrics['acts'].toString(),
          icon: Icons.medication,
          color: Colors.green.shade600,
        ),
        _buildMetricCard(
          title: 'Patients Uniques',
          value: metrics['patients'].toString(),
          icon: Icons.people,
          color: Colors.orange.shade600,
        ),
        _buildMetricCard(
          title: 'Montant Total',
          value: '${metrics['amount']} DT',
          icon: Icons.euro,
          color: Colors.purple.shade600,
        ),
        _buildMetricCard(
          title: 'Heures Total',
          value: '${metrics['hours']}h',
          icon: Icons.access_time,
          color: Colors.teal.shade600,
        ),
      ],
    );
  }

  Widget _buildTypeInterventionChart(List<Intervention> interventions) {
    final data = _groupByField(interventions, 'typeIntervention')
      .entries
      .map((e) => ChartData(e.key, e.value.toDouble()))
      .toList()
      ..sort((a, b) => b.y.compareTo(a.y));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Types d\'Intervention',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Nombre'),
                  minimum: 0,
                ),
                series: <ChartSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.x,
                    yValueMapper: (d, _) => d.y,
                    name: 'Interventions',
                    color: Colors.blue.shade400,
                    width: 0.6,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  )
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCharts(List<Intervention> interventions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(child: _buildDemographicChart(interventions, 'genre', 'Genre')),
              const SizedBox(width: 16),
              Expanded(child: _buildDemographicChart(interventions, 'ageCategory', 'Âge')),
              const SizedBox(width: 16),
              Expanded(child: _buildSectorChart(interventions)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildDemographicChart(interventions, 'genre', 'Genre'),
              const SizedBox(height: 16),
              _buildDemographicChart(interventions, 'ageCategory', 'Âge'),
              const SizedBox(height: 16),
              _buildSectorChart(interventions),
            ],
          );
        }
      },
    );
  }

  Widget _buildTrendCharts(List<Intervention> interventions) {
    return Column(
      children: [
        _buildMonthlyTrendChart(interventions, 'Interventions'),
        const SizedBox(height: 16),
        _buildMonthlyTrendChart(interventions, 'Actes', field: 'nbActesMedicaux'),
        const SizedBox(height: 16),
        _buildMonthlyTrendChart(interventions, 'Montant (DT)', field: 'montantPaye'),
      ],
    );
  }

  Widget _buildRecentInterventions(List<Intervention> interventions) {
    interventions.sort((a, b) => b.date!.compareTo(a.date!));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dernières Interventions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () => _showFullList(interventions),
                  child: const Text('Voir tout'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actes', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Établissement', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: interventions.take(10).map((i) => DataRow(
                  onSelectChanged: (_) => _showInterventionDetails(i),
                  cells: [
                    DataCell(Text(_dayFormat.format(i.date!))),
                    DataCell(Text(i.refugies ?? '')),
                    DataCell(Text(i.typeIntervention ?? '')),
                    DataCell(Text(i.nbActesMedicaux?.toString() ?? '0')),
                    DataCell(Text('${i.montantPaye?.toStringAsFixed(2)} DT')),
                    DataCell(Text(i.etablissementMedical ?? '')),
                  ],
                )).toList(),
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) => Colors.blue.shade50,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) => states.contains(MaterialState.hovered)
                    ? Colors.grey.shade100
                    : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicChart(List<Intervention> interventions, String field, String title) {
    final data = _groupByField(interventions, field)
      .entries
      .map((e) => ChartData(e.key, e.value.toDouble()))
      .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                palette: [Colors.blue.shade400, Colors.green.shade400, Colors.orange.shade400],
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.x,
                    yValueMapper: (d, _) => d.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    explode: true,
                    explodeIndex: 0,
                  )
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorChart(List<Intervention> interventions) {
    final data = _groupByField(interventions, 'secteur')
      .entries
      .map((e) => ChartData(e.key, e.value.toDouble()))
      .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Répartition par Secteur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                palette: [Colors.purple.shade400, Colors.teal.shade400],
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.x,
                    yValueMapper: (d, _) => d.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  )
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<Intervention> interventions, String title, {String field = ''}) {
    final data = _groupByMonth(interventions, field: field)
      .entries
      .map((e) => ChartData(_monthFormat.format(e.key), e.value))
      .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(minimum: 0),
                series: <ChartSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.x,
                    yValueMapper: (d, _) => d.y,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: Colors.blue.shade400,
                    width: 3,
                  )
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Row(
              children: List.generate(5, (i) => Expanded(
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez par ajouter des interventions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les données'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...['Tout', '7 jours', '1 mois', '3 mois', '1 an', 'Personnalisé']
                .map((filter) => RadioListTile(
                  title: Text(filter),
                  value: filter.toLowerCase().replaceAll(' ', ''),
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    if (value == 'custom') {
                      _selectDateRange(context);
                    } else {
                      setState(() {
                        _selectedFilter = value.toString();
                        _startDate = null;
                        _endDate = null;
                      });
                    }
                    Navigator.pop(context);
                  },
                ))
                .toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullList(List<Intervention> interventions) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toutes les interventions (${interventions.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actes', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Établissement', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Secteur', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: interventions.map((i) => DataRow(
                        onSelectChanged: (_) => _showInterventionDetails(i),
                        cells: [
                          DataCell(Text(_dayFormat.format(i.date!))),
                          DataCell(Text(i.refugies ?? '')),
                          DataCell(Text(i.typeIntervention ?? '')),
                          DataCell(Text(i.nbActesMedicaux?.toString() ?? '0')),
                          DataCell(Text('${i.montantPaye?.toStringAsFixed(2)} DT')),
                          DataCell(Text(i.etablissementMedical ?? '')),
                          DataCell(Text(i.secteur ?? '')),
                        ],
                      )).toList(),
                      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) => Colors.blue.shade50,
                      ),
                      dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) => states.contains(MaterialState.hovered)
                          ? Colors.grey.shade100
                          : null,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _exportToCSV(interventions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Exporter en CSV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterventionDetails(Intervention intervention) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'intervention'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', _dayFormat.format(intervention.date!)),
              _buildDetailRow('Patient', intervention.refugies ?? ''),
              _buildDetailRow('Type', intervention.typeIntervention ?? ''),
              _buildDetailRow('Actes', intervention.nbActesMedicaux?.toString() ?? '0'),
              _buildDetailRow('Montant', '${intervention.montantPaye?.toStringAsFixed(2)} DT'),
              _buildDetailRow('Établissement', intervention.etablissementMedical ?? ''),
              _buildDetailRow('Secteur', intervention.secteur ?? ''),
              if (intervention.description?.isNotEmpty ?? false)
                _buildDetailRow('Description', intervention.description!),
              if (intervention.remarques?.isNotEmpty ?? false)
                _buildDetailRow('Remarques', intervention.remarques!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMetrics(List<Intervention> interventions) {
    return {
      'count': interventions.length,
      'acts': interventions.fold<int>(0, (sum, i) => sum + (i.nbActesMedicaux ?? 0)),
      'patients': interventions.map((i) => i.carteNumero).toSet().length,
      'amount': interventions.fold<double>(0, (sum, i) => sum + (i.montantPaye ?? 0)).toStringAsFixed(2),
      'hours': interventions.fold<double>(0, (sum, i) => sum + (i.heuresTravail ?? 0)).toStringAsFixed(1),
    };
  }

  Map<String, int> _groupByField(List<Intervention> interventions, String field) {
    final map = <String, int>{};
    for (var i in interventions) {
      final value = i.toMap()[field]?.toString() ?? 'Non spécifié';
      map.update(value, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

Map<DateTime, double> _groupByMonth(List<Intervention> interventions, {String field = ''}) {
  final map = <DateTime, double>{};
  for (var i in interventions) {
    if (i.date == null) continue;
    
    final month = DateTime(i.date!.year, i.date!.month);
    final dynamic fieldValue = i.toMap()[field];
    final double value;
    
    if (field.isEmpty) {
      value = 1.0;
    } else if (fieldValue == null) {
      value = 0.0;
    } else if (fieldValue is int) {
      value = fieldValue.toDouble();
    } else if (fieldValue is double) {
      value = fieldValue;
    } else {
      value = 0.0;
    }
    
    map.update(
      month, 
      (v) => v + value, 
      ifAbsent: () => value
    );
  }
  return map;
}
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
class _CustomReportDialog extends StatefulWidget {
  final List<String> fields;

  const _CustomReportDialog({required this.fields});

  @override
  __CustomReportDialogState createState() => __CustomReportDialogState();
}

class __CustomReportDialogState extends State<_CustomReportDialog> {
  final Map<String, bool> _selectedFields = {};

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      _selectedFields[field] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un rapport personnalisé'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sélectionnez les champs à inclure:'),
            const SizedBox(height: 16),
            ...widget.fields.map((field) => CheckboxListTile(
              title: Text(_getFieldLabel(field)),
              value: _selectedFields[field] ?? false,
              onChanged: (value) {
                setState(() {
                  _selectedFields[field] = value!;
                });
              },
            )).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final selected = _selectedFields.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Générer le rapport'),
        ),
      ],
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'date': return 'Date';
      case 'volontaire': return 'Volontaire';
      case 'refugies': return 'Patient';
      case 'typeIntervention': return 'Type Intervention';
      case 'nbActesMedicaux': return 'Nombre d\'actes';
      case 'montantPaye': return 'Montant payé';
      case 'etablissementMedical': return 'Établissement médical';
      case 'secteur': return 'Secteur';
      case 'description': return 'Description';
      default: return field;
    }
  }
}