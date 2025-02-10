import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'DashboardPage.dart';
import 'MessagesPage.dart';
import 'ClientOverviewPage.dart';

class ClientManagementApp extends StatefulWidget {
  @override
  _ClientManagementAppState createState() => _ClientManagementAppState();
}

class _ClientManagementAppState extends State<ClientManagementApp> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> clients = [];
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  String coachId = '';

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    fetchClients();
    // Initialize pages once clients are fetched
    _pages = [
      ClientsPage(),  // This will be dynamically updated when clients are fetched
      DashboardPage(),
      MessagesPage(),
    ];
  }

  Future<void> fetchClients() async {
    coachId = FirebaseAuth.instance.currentUser?.uid ?? "";
    var coachRef = FirebaseFirestore.instance.collection('coaches').doc(coachId);
    var snapshot = await coachRef.collection('clients').get();
    var fetchedClients = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    setState(() {
      clients = fetchedClients;
      // Update the ClientsPage with the fetched clients
      _pages[0] = ClientsPage(clients: clients);
    });
  }

  Future<void> _addClient() async {
    Navigator.of(context).pop(); // Close the dialog
    try {
      var userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: "defaultPassword123", // Consider a more secure handling method
      );
      var clientData = {
        'first name': firstNameController.text,
        'last name': lastNameController.text,
        'email': emailController.text,
        'uid': userCredential.user!.uid,
      };
      await FirebaseFirestore.instance.collection('coaches').doc(coachId)
          .collection('clients').doc(userCredential.user!.uid).set(clientData);
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(clientData);

      setState(() {
        clients.add(clientData);
        // Update the ClientsPage with the new list of clients
        _pages[0] = ClientsPage(clients: clients);
        firstNameController.clear();
        lastNameController.clear();
        emailController.clear();
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Failed to create client"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Client"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: _addClient,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Management System'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddClientDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),  // Update this line
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class ClientsPage extends StatelessWidget {
  final List<Map<String, dynamic>> clients;

  ClientsPage({this.clients = const []});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: clients.map((client) => ListTile(
        title: Text(client['first name'] + " " + client['last name']),
        subtitle: Text(client['email']),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ClientOverviewPage(
                  clientId: client['uid'],
                  clientName: client['first name'] + " " + client['last name'],
                  clientEmail: client['email'],
                )
            ),
          );
        },
      )).toList(),
    );
  }
}
