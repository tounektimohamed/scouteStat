import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intervention_stats/models/intervention.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:csv/csv.dart';

class StatsScreen extends StatelessWidget {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat dateFormat = DateFormat('MMM yyyy');
  Future<void> _exportToCSV(
      BuildContext context, List<Intervention> interventions) async {
    try {
      // Création du contenu CSV
      List<List<dynamic>> csvData = [];

      // En-têtes
      csvData.add([
        'Date',
        'Volontaire',
        'Heures',
        'Type Intervention',
        'Établissement',
        'Type Établissement',
        'Secteur',
        'Région',
        'Sexe Bénéficiaire',
        'Âge Bénéficiaire'
      ]);

      // Données
      for (var intervention in interventions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(intervention.dateIntervention!),
          intervention.nomVolontaire ?? '',
          intervention.heuresTravail?.toStringAsFixed(1) ?? '0.0',
          intervention.typeIntervention ?? '',
          intervention.etablissement ?? '',
          intervention.typeEtablissement ?? '',
          intervention.secteur ?? '',
          intervention.region ?? '',
          intervention.sexeRefugie ?? '',
          intervention.ageRefugie ?? ''
        ]);
      }

      // Conversion en CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // Création d'un blob et téléchargement
      final blob = html.Blob([csv], 'text/csv', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download =
            'interventions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv'
        ..click();

      // Nettoyage
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Erreur lors de l\'export CSV: $e');
      // Afficher un snackbar avec l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('interventions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: null,
                  tooltip: 'Export unavailable',
                );
              }

              return IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  final interventions = snapshot.data!.docs.map((doc) {
                    return Intervention.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();
                  _exportToCSV(context, interventions);
                },
                tooltip: 'Exporter en CSV',
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('interventions').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.insert_chart_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune donnée disponible',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez par ajouter des interventions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            try {
              final interventions = snapshot.data!.docs.map((doc) {
                return Intervention.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCards(context, interventions),
                    const SizedBox(height: 24),
                    _buildTypeInterventionChart(context, interventions),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _buildRegionChart(context, interventions)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSexeVolontaireChart(
                                context, interventions)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildHeuresTravailChart(context, interventions),
                    const SizedBox(height: 24),
                    _buildMonthlyTrendChart(context, interventions),
                    const SizedBox(height: 24),
                    _buildAgeRefugieChart(context, interventions),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTypeEtablissementChart(
                                context, interventions)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSecteurChart(context, interventions)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildVolontaireStats(context, interventions),
                  ],
                ),
              );
            } catch (e) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de traitement des données',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildAgeRefugieChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByAgeRefugie(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Répartition par Âge des Bénéficiaires',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(title: AxisTitle(text: 'Nombre')),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Bénéficiaires',
                    color: Colors.orange,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeEtablissementChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByTypeEtablissement(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Type d\'Établissement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecteurChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupBySecteur(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Secteur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    pointColorMapper: (ChartData data, _) {
                      return data.x == 'Privé'
                          ? Colors.blue.shade400
                          : Colors.green.shade400;
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolontaireStats(
      BuildContext context, List<Intervention> interventions) {
    final volontaires = _groupByVolontaire(interventions);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rapport par Volontaire',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Tableau avec en-têtes
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Volontaire',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('Interventions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('Heures',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 20),
            // Données
            ...volontaires.entries.map((entry) {
              final interventions = entry.value;
              final totalHeures = interventions.fold<double>(
                  0.0, (sum, i) => sum + (i.heuresTravail ?? 0.0));
              final count = interventions.length;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text('$count'),
                    ),
                    Expanded(
                      child: Text('${totalHeures.toStringAsFixed(1)}'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Map<String, int> _groupByAgeRefugie(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.ageRefugie != null) {
        map.update(
          intervention.ageRefugie!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, int> _groupByTypeEtablissement(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.typeEtablissement != null) {
        map.update(
          intervention.typeEtablissement!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, int> _groupBySecteur(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.secteur != null) {
        map.update(
          intervention.secteur!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, List<Intervention>> _groupByVolontaire(
      List<Intervention> interventions) {
    final map = <String, List<Intervention>>{};
    for (var intervention in interventions) {
      if (intervention.nomVolontaire != null) {
        map.update(
          intervention.nomVolontaire!,
          (list) => [...list, intervention],
          ifAbsent: () => [intervention],
        );
      }
    }
    return map;
  }

  Widget _buildSummaryCards(
      BuildContext context, List<Intervention> interventions) {
    final totalHours = interventions.fold<double>(
        0.0, (sum, i) => sum + (i.heuresTravail ?? 0.0));
    final totalInterventions = interventions.length;
    final regions = _groupByRegion(interventions).keys.toList();

    return Row(
      children: [
        Expanded(
            child: _buildSummaryCard(
          title: 'Total Heures',
          value: '${totalHours.toStringAsFixed(1)}h',
          icon: Icons.access_time,
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard(
          title: 'Interventions',
          value: totalInterventions.toString(),
          icon: Icons.assignment,
          color: Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard(
          title: 'Régions',
          value: regions.length.toString(),
          icon: Icons.map,
          color: Colors.orange,
        )),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, size: 20, color: color.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeInterventionChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByTypeIntervention(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Types d\'Intervention',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Nombre'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Interventions',
                    color: Colors.blue,
                    width: 0.6,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByRegion(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Répartition par Région',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: '10%',
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSexeVolontaireChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupBySexeVolontaire(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value.toDouble()))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Sexe des Volontaires',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                    ),
                    innerRadius: '70%',
                    pointColorMapper: (ChartData data, _) {
                      return data.x == 'Homme'
                          ? Colors.blue.shade400
                          : Colors.pink.shade300;
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeuresTravailChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByHeuresTravail(interventions)
        .entries
        .map((e) => ChartData(e.key, e.value))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Heures de Travail par Région',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Heures'),
                ),
                series: <ChartSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Heures',
                    color: Colors.green,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(
      BuildContext context, List<Intervention> interventions) {
    final data = _groupByMonth(interventions)
        .entries
        .map((e) => ChartData(dateFormat.format(e.key), e.value.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tendance Mensuelle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Nombre d\'interventions'),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ChartSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'Interventions',
                    color: Colors.purple,
                    markerSettings: const MarkerSettings(isVisible: true),
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _groupByTypeIntervention(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.typeIntervention != null) {
        map.update(
          intervention.typeIntervention!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, int> _groupByRegion(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.region != null) {
        map.update(
          intervention.region!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, int> _groupBySexeVolontaire(List<Intervention> interventions) {
    final map = <String, int>{};
    for (var intervention in interventions) {
      if (intervention.sexeVolontaire != null) {
        map.update(
          intervention.sexeVolontaire!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }

  Map<String, double> _groupByHeuresTravail(List<Intervention> interventions) {
    final map = <String, double>{};
    for (var intervention in interventions) {
      if (intervention.region != null && intervention.heuresTravail != null) {
        map.update(
          intervention.region!,
          (value) => value + intervention.heuresTravail!,
          ifAbsent: () => intervention.heuresTravail!,
        );
      }
    }
    return map;
  }

  Map<DateTime, int> _groupByMonth(List<Intervention> interventions) {
    final map = <DateTime, int>{};
    for (var intervention in interventions) {
      if (intervention.dateIntervention != null) {
        final month = DateTime(
          intervention.dateIntervention!.year,
          intervention.dateIntervention!.month,
        );
        map.update(
          month,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return map;
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
