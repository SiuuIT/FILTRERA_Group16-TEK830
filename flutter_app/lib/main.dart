import 'package:flutter/material.dart';
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
class _MyHomePageState extends State<MyHomePage>  {
  bool showStats = false;
  int refresher = 0; //variable for refreshing the statistics area
  void toggleOrRefresh(){
    setState((){
      if (!showStats){
        showStats = true; 
        refresher = 1; 
      }
      else{
        refresher++;
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ikea App',
      
      home:Scaffold(
        backgroundColor: Colors.white,  
        
        body: Row(
          children: [
            Expanded(
              child:Container(
                margin: EdgeInsets.all(16.0),
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Factory Safety Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Analyze accident data and identify dangerous areas', style: TextStyle(fontSize: 12)),

                    Container(
                      decoration:BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(8.0),
                      
                      child:Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Filter Accident Data"),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                            Column(
                              children:[
                                //want a dropdown here
                                CustomDropdown(
                                  label: "Factory",
                                  items: ["Factory A", "Factory B", "Factory C"],
                                  initialValue: "Factory A",
                                  onChanged: (value) {
                                    // Handle selection change
                                  },
                                ),

                                CustomDropdown(
                                  label: "Section",
                                  items: ["Factory A", "Factory B", "Factory C"],
                                  initialValue: "Factory A",
                                  onChanged: (value) {
                                    // Handle selection change
                                  },
                                ),
                              ]
                            ),
                          ),
                          ElevatedButton(
                          onPressed: toggleOrRefresh, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(showStats ? 'Refresh Statistics Area' : 'Load Statistics Area')
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
              child:Container(
                decoration:BoxDecoration(
                  border: Border.all(
                     color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.all(8.0),
                width: double.infinity,
                height: double.infinity,
                child:Center( 
                  // by sending a new key, the widget is rebuilt from scratch
                  child: showStats ? StatisticsAreaWidget(key: ValueKey(refresher)) : Text('Main Area')
                ),
              ),
            ),
          ],
        ),
      )
      
    );
  }
}
