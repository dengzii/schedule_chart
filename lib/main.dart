import 'package:flutter/material.dart';
import 'package:schedule_chart/schedule_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule Chart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            letterSpacing: -1.5,
            color: Colors.black,
          ),
          displayMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          displaySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -1.5,
            color: Colors.black,
          ),
        )
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 50),
      child: const ScheduleChart(),
    );
  }
}
