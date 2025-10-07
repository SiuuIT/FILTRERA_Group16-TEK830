import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget  {
  const PieChartWidget({super.key}); 
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData( 
        sections: [ 
          PieChartSectionData( 
            color: Colors.blue,
            value: 40,
            title: '40%',
            
          ),
          PieChartSectionData( 
            color: Colors.red,
            value: 30,
            title: '30%',
          ),
          PieChartSectionData( 
            color: Colors.green,
            value: 20,
            title: '20%',
          ),
        ]
      ),
    );
  }
}