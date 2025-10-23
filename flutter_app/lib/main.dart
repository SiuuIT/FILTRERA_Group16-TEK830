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

  final ApiService api = ApiService('http://127.0.0.1:8000');

  List<String> factories = [];
  List<String> categories = [];
  String? selectedFactory;
  String? selectedCategory;

  Map<String, dynamic> aggregates = {};
  Map<String, dynamic>? aiAnswer;
  Map<String, dynamic> locationCounts = {};
  List<Map<String, dynamic>> reports = [];

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

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
        factories = List<String>.from(data);
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
        categories = List<String>.from(data);
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
    final filters = <String, dynamic>{};

    if (selectedFactory != null && selectedFactory!.isNotEmpty) {
      filters['Factory'] = selectedFactory!;
    }
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filters['Category'] = selectedCategory!;
    }
    if (fromDateController.text.isNotEmpty || toDateController.text.isNotEmpty) {
      filters['When did it happen?'] = {
        if (fromDateController.text.isNotEmpty) 'from': fromDateController.text,
        if (toDateController.text.isNotEmpty) 'to': toDateController.text,
      };
    }

    try {
      final response = await api.filterData(filters: filters, limit: 50, threshold: 70);

      final rawAI = response['AIAnswer'];
      final rawReports = response['accident_reports'] ?? response['reports'];

      setState(() {
        aggregates = Map<String, dynamic>.from(response['aggregates'] ?? {});
        aiAnswer = (rawAI is Map<String, dynamic>) ? rawAI : (rawAI == null ? null : {'summary': rawAI.toString()});
        locationCounts = Map<String, dynamic>.from(response['location_counts'] ?? {});
        reports = (rawReports is List)
            ? rawReports.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
      });

      debugPrint('Aggregates: $aggregates');
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
                                  items: factories,
                                  initialValue: selectedFactory,
                                  onChanged: (value) {
                                    setState(() => selectedFactory = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: fromDateController,
                                  decoration: const InputDecoration(
                                    labelText: "From Date",
                                    hintText: "(yyyy-mm-dd)",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: toDateController,
                                  decoration: const InputDecoration(
                                    labelText: "To Date",
                                    hintText: "(yyyy-mm-dd)",
                                    border: OutlineInputBorder(),
                                  ),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(showStats ? 'Refresh Statistics Area' : 'Load Statistics Area'),
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
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1)),
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(8.0),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: showStats
                      ? StatisticsAreaWidget(
                          key: ValueKey(refresher),
                          aggregates: aggregates,
                          aiAnswer: aiAnswer,
                          locationCounts: locationCounts,
                          reports: reports, // <-- pass dynamic reports (where/what/category)
                        )
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
