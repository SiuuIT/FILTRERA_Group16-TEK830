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
  bool isRefreshing = false; //controlles refresh main page 
  final ApiService api = ApiService('http://127.0.0.1:8000');

  // Data for filters
  List<String> factories = [];
  List<String> categories = [];
  String? selectedFactory;
  String? selectedCategory;

  // Results for right-hand statistics area
  Map<String, dynamic> aggregates = {};
  Map<String, dynamic>? aiAnswer;
  Map<String, dynamic> locationCounts = {};
  List<Map<String, dynamic>> reports = [];

  // Date inputs
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  // AI input
  final TextEditingController aiController = TextEditingController();
  bool aiLoading = false;
  String? aiExplanation;

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
        if (factories.isNotEmpty && selectedFactory == null) {
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
        if (categories.isNotEmpty && selectedCategory == null) {
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
        aiAnswer = (rawAI is Map<String, dynamic>) ? rawAI : (rawAI == null ? null : {'summary:': rawAI.toString()});
        locationCounts = Map<String, dynamic>.from(response['heatmap_data'] ?? {});
        reports = (rawReports is List)
            ? rawReports.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
      });

      debugPrint('Aggregates: $aggregates');
    } catch (e) {
      debugPrint('Error applying filters: $e');
    }
  }

  Future<void> askAIAndAutofill() async {
    setState(() {
      aiLoading = true;
      aiExplanation = null;
    });
    try {
      final result = await api.interpretFilters(aiController.text);
      if (result != null && result['filters'] != null) {
        final filters = result['filters'] as Map<String, dynamic>;
        final String? aiFactory = filters['Factory'] as String?;
        print('AI suggested factory: $aiFactory');
        final Map<String, dynamic>? date = filters['date'] as Map<String, dynamic>?;

        // Autofill factory
        if (aiFactory != null && aiFactory.isNotEmpty) {
          // If factory list already contains the suggested one, pick it; otherwise keep current selection
          if (factories.contains(aiFactory)) {
            selectedFactory = aiFactory;
          }
        }

        // Autofill dates
        if (date != null) {
          final String? from = date['from']?.toString();
          final String? to = date['to']?.toString();
          if (from != null && from.isNotEmpty) {
            fromDateController.text = from;
          }
          if (to != null && to.isNotEmpty) {
            toDateController.text = to;
          }
        }

        setState(() {
          aiExplanation = "AI selected these filters based on your input.";
        });
      } else {
        setState(() {
          aiExplanation = "AI could not interpret your input.";
        });
      }
    } catch (e) {
      debugPrint('AI error: $e');
      setState(() {
        aiExplanation = "AI request failed.";
      });
    } finally {
      setState(() {
        aiLoading = false;
      });
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
            // LEFT SIDEBAR
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
                    const SizedBox(height: 10),

                    // AI input is here, between description and the filter card
                    TextField(
                      controller: aiController,
                      decoration: const InputDecoration(
                        labelText: "What statistics are you looking for?",
                        prefixIcon: Icon(Icons.smart_toy_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: aiLoading ? null : askAIAndAutofill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Ask AI"),
                        ),
                        const SizedBox(width: 10),
                        if (aiLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (aiExplanation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        aiExplanation!,
                        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Existing filter card
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
                                  selectedValue: selectedFactory, // ändrat namn här också
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
                            onPressed: () async {
                              // Ensure the statistics area is shown
                              if (!showStats) {
                                setState(() {
                                  showStats = true;
                                  refresher = 1;
                                });
                              }

                              // Trigger loader inside StatisticsAreaWidget
                              setState(() => isRefreshing = true);

                              // Fetch backend data
                              await applyFilter();

                              // Stop loader once backend responds
                              setState(() => isRefreshing = false);
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

            // RIGHT MAIN AREA
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
                          reports: reports,
                          isRefreshing: isRefreshing,
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
