// main.dart
// Uses ApiService, dynamically fetches unique factories and categories, and shows them in dropdowns.

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'widgets/statisicAreaWidget.dart';
import 'widgets/drop_down_widget.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showStats = false;
  int refresher = 0;

  // Backend service (local FastAPI)
  final ApiService api = ApiService('http://127.0.0.1:8000');

  // Dropdown data
  List<String> factories = [];
  List<String> categories = [];
  String? selectedFactory;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchFactories();
    fetchCategories();
  }

  Future<void> fetchFactories() async {
    try {
      final data = await api.getUniqueValues('Factory');
      setState(() {
        factories = data;
        if (factories.isNotEmpty) {
          selectedFactory = factories.first;
        }
      });
    } catch (e) {
      debugPrint('Error fetching factories: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final data = await api.getUniqueValues('Category');
      setState(() {
        categories = data;
        if (categories.isNotEmpty) {
          selectedCategory = categories.first;
        }
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  void toggleOrRefresh() {
    setState(() {
      if (!showStats) {
        showStats = true;
        refresher = 1;
      } else {
        refresher++;
      }
    });
  }

  Future<void> applyFilter() async {
  // Build the map of filters based on selected dropdowns
  final filters = <String, String>{};

  if (selectedFactory != null && selectedFactory!.isNotEmpty) {
    filters['Factory'] = selectedFactory!;
  }
  if (selectedCategory != null && selectedCategory!.isNotEmpty) {
    filters['Category'] = selectedCategory!;
  }

  if (filters.isEmpty) {
    debugPrint('No filters selected.');
    return;
  }

  try {
    final results = await api.filterData(
      filters: filters,
      limit: 50,
      threshold: 70,
    );

    debugPrint('Received ${results.length} rows from backend.');
    debugPrint('what we recieved ${results}');
  } catch (e) {
    debugPrint('Error applying filters: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ikea App',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Factory Safety Analytics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Analyze accident data and identify dangerous areas',
                      style: TextStyle(fontSize: 12),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Filter Accident Data"),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                CustomDropdown(
                                  label: "Factory",
                                  items: factories.isNotEmpty ? factories : ['Loading...'],
                                  initialValue: selectedFactory,
                                  onChanged: (value) {
                                    setState(() => selectedFactory = value);
                                  },
                                ),
                                CustomDropdown(
                                  label: "Category",
                                  items: categories.isNotEmpty ? categories : ['Loading...'],
                                  initialValue: selectedCategory,
                                  onChanged: (value) {
                                    setState(() => selectedCategory = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              toggleOrRefresh();
                              applyFilter();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              showStats ? 'Refresh Statistics Area' : 'Load Statistics Area',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(8.0),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: showStats
                      ? StatisticsAreaWidget(key: ValueKey(refresher))
                      : const Text('Main Area'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
