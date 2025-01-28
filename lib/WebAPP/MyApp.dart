import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // Ensure you import the Firebase options
import '../pages/LoginOrRegisterPage.dart';
import 'ClientOverviewPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Client Management System',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return snapshot.hasData ? HomePage() : LoginOrRegisterPage();
          }
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  List<Map<String, dynamic>> clients = [];
  final String coachId = FirebaseAuth.instance.currentUser?.uid ?? ""; // Assumes coach is logged in

  @override
  void initState() {
    super.initState();
    fetchClients();
  }
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clients"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddClientDialog(),
          ),
          IconButton(
            //sign out button
            onPressed: signUserOut,
            icon: Icon(Icons.logout),
          )
        ],

      ),
      body: ListView(
        children: clients.map((client) => ListTile(
          title: Text(client['first name'] + " " + client['last name']),
          subtitle: Text(client['email']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClientOverviewPage(
                clientId: client['uid'],
                clientName: client['first name'] + " " + client['last name'],
                clientEmail: client['email'],
              )),
            );
          },
        )).toList(),

      ),

    );
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
              onPressed: () => _addClient(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addClient() async {
    Navigator.of(context).pop(); // Close the dialog

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: "defaultPassword123", // You should consider implementing a more secure way to handle client passwords
      );

      // Prepare client data
      Map<String, String> clientData = {
        'first name': firstNameController.text,
        'last name': lastNameController.text,
        'email': emailController.text,
        'uid': userCredential.user!.uid,
      };

      // Save the new client's details in Firestore under the coach's clients sub-collection
      DocumentReference coachRef = FirebaseFirestore.instance.collection('coaches').doc(coachId);
      await coachRef.collection('clients').doc(userCredential.user!.uid).set(clientData);

      // Also save the client's details in the general users collection
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(clientData);

      // Add to local list to update UI
      setState(() {
        clients.add(clientData);
        firstNameController.clear();
        lastNameController.clear();
        emailController.clear();
      });
    } on FirebaseAuthException catch (e) {
      // Handle errors, such as email already in use, weak password, etc.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Failed to create client"),
          content: Text(e.message ?? "An unexpected error occurred"),
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

  Future<void> fetchClients() async {
    DocumentReference coachRef = FirebaseFirestore.instance.collection('coaches').doc(coachId);
    QuerySnapshot snapshot = await coachRef.collection('clients').get();
    List<Map<String, dynamic>> fetchedClients = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    setState(() {
      clients = fetchedClients;
    });
  }
}
