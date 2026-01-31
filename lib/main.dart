import 'package:flutter/material.dart';

import 'pages/rate_contacts_page.dart';
import 'pages/roulette_page.dart';
import 'pages/select_contacts_page.dart';
import 'pages/stats_page.dart';

void main() {
  runApp(const PhoneRouletteApp());
}

class PhoneRouletteApp extends StatelessWidget {
  const PhoneRouletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Roulette',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Compact sizing for small screens
        visualDensity: VisualDensity.compact,
        appBarTheme: const AppBarTheme(
          toolbarHeight: 44,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(fontSize: 10),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          selectedIconTheme: IconThemeData(size: 22),
          unselectedIconTheme: IconThemeData(size: 20),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Start on Spin tab

  // GlobalKeys to call refresh when switching tabs
  final _selectKey = GlobalKey<SelectContactsPageState>();
  final _rateKey = GlobalKey<RateContactsPageState>();
  final _spinKey = GlobalKey<RoulettePageState>();
  final _statsKey = GlobalKey<StatsPageState>();

  final List<String> _titles = ['Select', 'Rate', 'Spin', 'Stats'];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    
    // Refresh Select page when switching to it (index 0)
    if (index == 0) {
      _selectKey.currentState?.refresh();
    }
    // Refresh Rate page when switching to it (index 1)
    if (index == 1) {
      _rateKey.currentState?.refresh();
    }
    // Refresh Spin page when switching to it (index 2)
    if (index == 2) {
      _spinKey.currentState?.refresh();
    }
    // Refresh Stats page when switching to it (index 3)
    if (index == 3) {
      _statsKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        elevation: 1,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SelectContactsPage(key: _selectKey),
          RateContactsPage(key: _rateKey),
          RoulettePage(key: _spinKey),
          StatsPage(key: _statsKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            activeIcon: Icon(Icons.person_add),
            label: 'Select',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            activeIcon: Icon(Icons.tune),
            label: 'Rate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            activeIcon: Icon(Icons.casino),
            label: 'Spin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
