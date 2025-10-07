import 'package:flutter/material.dart';
import 'statisticWidgets/pie_chart.dart';
//this is the usable widget
class StatisticsAreaWidget extends StatefulWidget{
  const StatisticsAreaWidget({super.key});
  @override
  State<StatisticsAreaWidget> createState() => _StatisticsAreaWidgetState();

}

class _StatisticsAreaWidgetState extends State<StatisticsAreaWidget>{
  bool showStats = false; 
  int counter = 0;
  // toggles between beeing loaded and not loaded
  @override
  void initState(){
    super.initState();
    showStats = true; 
    counter++;
  }
  
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: ConstrainedBox(
      // prevent children from receiving unbounded height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Accident Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Distribution of accidents by type', style: TextStyle(fontSize: 12)),
                // Give the chart a bounded height to avoid unbounded/Expanded inside a scrollable
                SizedBox(height: 120, child: PieChartWidget()),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Accident Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Distribution of accidents by type', style: TextStyle(fontSize: 12)),
                // Give the chart a bounded height to avoid unbounded/Expanded inside a scrollable
                SizedBox(height: 120, child: PieChartWidget()),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}