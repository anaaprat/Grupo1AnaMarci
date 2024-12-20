import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:eventify/services/graphic_service.dart';
import 'package:eventify/models/Category.dart';

class GraphicsScreen extends StatefulWidget {
  final String token;
  final int organizerId;

  const GraphicsScreen({
    Key? key,
    required this.token,
    required this.organizerId,
  }) : super(key: key);

  @override
  _GraphicsScreenState createState() => _GraphicsScreenState();
}

class _GraphicsScreenState extends State<GraphicsScreen> {
  late GraphicService graphicService;
  Map<String, int> chartData = {};
  List<Category> categories = [];
  String? selectedCategory;
  bool isLoading = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    graphicService = GraphicService(token: widget.token);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    try {
      // Recupera las categorías desde el servicio
      final fetchedCategories = await graphicService.fetchCategories();

      // Asegúrate de mapear solo si los elementos son JSON
      categories = List<Category>.from(fetchedCategories);

      if (categories.isNotEmpty) {
        selectedCategory = categories.first.name;
        await _loadChartData();
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadChartData() async {
    if (selectedCategory == null) return;

    setState(() => isLoading = true);
    try {
      final data = await graphicService.fetchRegisteredCountByMonthAndCategory(
        widget.organizerId,
        selectedCategory!,
      );

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available for this category.')),
        );
      }

      setState(() {
        chartData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chart data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphics'),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories
                        .map((category) => DropdownMenuItem<String>(
                              value: category.name,
                              child: Text(category.name),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedCategory = value;
                      });
                      await _loadChartData();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: chartData.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available for this category.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= chartData.keys.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          chartData.keys.elementAt(index),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: chartData.entries
                                  .map(
                                    (entry) => BarChartGroupData(
                                      x: chartData.keys
                                          .toList()
                                          .indexOf(entry.key),
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.toDouble(),
                                          color: Colors.purple,
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  )
                ],
              ),
            ),
    );
  }
}
