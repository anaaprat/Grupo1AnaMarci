import 'package:flutter/material.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/services/graphic_service.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphicsTab extends StatefulWidget {
  final String token;

  const GraphicsTab({Key? key, required this.token}) : super(key: key);

  @override
  _GraphicsTabState createState() => _GraphicsTabState();
}

class _GraphicsTabState extends State<GraphicsTab> {
  List<dynamic> categories = [];
  String? selectedCategory;
  bool isLoading = true;
  late UserService userService;
  late GraphicService graphicService;
  Map<String, int> monthlyData = {}; // Mapa vacío inicial

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    graphicService = GraphicService(token: widget.token);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await userService.getCategories();
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Desplegable para seleccionar categoría
              DropdownButton<String>(
                hint: const Text('Selecciona una categoría'),
                value: selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedCategory = value;
                    isLoading = true;
                  });

                  // Obtener category_id
                  final category =
                      categories.firstWhere((c) => c['name'] == value);
                  int categoryId = category['id'];

                  // Simulación de organizer_id (reemplaza con el ID real)
                  int organizerId = 1;

                  // Llamar a la función para obtener los usuarios registrados
                  final data = await graphicService
                      .fetchRegisteredUsersByCategory(organizerId, categoryId);

                  setState(() {
                    monthlyData = data;
                    isLoading = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Gráfico dinámico
              Expanded(
                child: selectedCategory == null
                    ? const Center(child: Text('Selecciona una categoría'))
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: true)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final months = monthlyData.keys.toList();
                                    return Text(months[value.toInt()]);
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                            ),
                            barGroups: monthlyData.entries.map((entry) {
                              return BarChartGroupData(
                                x: monthlyData.keys.toList().indexOf(entry.key),
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    width: 15,
                                    color: Colors.purple,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          );
  }
}
