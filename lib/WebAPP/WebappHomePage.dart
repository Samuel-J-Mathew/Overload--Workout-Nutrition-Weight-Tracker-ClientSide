import 'package:flutter/material.dart';
import 'package:gymapp/WebAPP/DashboardPage.dart';
import 'package:gymapp/WebAPP/MessagesPage.dart';

// Placeholder for the missing MyApp implementation
class PlaceholderWidget extends StatelessWidget {
  final String text;

  PlaceholderWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text),
    );
  }
}

class WebAppHomePage extends StatefulWidget {
  @override
  _WebAppHomePageState createState() => _WebAppHomePageState();
}

class _WebAppHomePageState extends State<WebAppHomePage> {
  int _selectedIndex = 0; // Keeps track of the selected page
  List<Widget> _pages = [
    PlaceholderWidget('Clients Page'), // Placeholder for MyApp
    DashboardPage(),
    MessagesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.people),
                selectedIcon: Icon(Icons.people_outline),
                label: Text('Clients'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard_customize),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.message),
                selectedIcon: Icon(Icons.message_outlined),
                label: Text('Messages'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex], // Display the selected page
          ),
        ],
      ),
    );
  }
}
