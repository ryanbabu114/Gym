import 'package:flutter/material.dart';
import 'package:gym/pages/Clientpage/ClientPage.dart';
import 'package:gym/pages/Homepage/LoginPage.dart';
import 'package:gym/pages/Trainerpage/TrainerPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zajdlwpkfzclakggrbpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphamRsd3BrZnpjbGFrZ2dyYnBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5MjYxODUsImV4cCI6MjA1NzUwMjE4NX0.lQMt2o2aZNRtNJVJs4UlP-qA17CE3a6zBto24Ho19ZM',  // Store securely instead of hardcoding
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session != null
          ? _redirectUserBasedOnRole(session)
          : GymHomePage(),
    );
  }

  // Function to redirect user based on role
  Widget _redirectUserBasedOnRole(Session session) {
    final email = session.user.email!;

    // Example: Checking role based on email (replace with actual role-checking logic)
    if (email.contains('trainer')) {
      return TrainerPage(username: email);
    } else {
      return ClientPage(username: email);
    }
  }
}


class GymHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Gym Management System',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo[600],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Text('Are you a Trainer or a Client?',
                style: TextStyle(fontSize: 25, color: Colors.black)),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage(isTrainer: false)),
                );
              },
              child: const Text('Client', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage(isTrainer: true)),
                );
              },
              child: const Text('Trainer', style: TextStyle(fontSize: 22)),
            ),
          ],
        ),
      ),
    );
  }
}




class CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String label;
  final String imageurl;

  CircleButton({
    required this.icon,
    this.color,
    required this.label,
    required this.imageurl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.height,
          // Smaller size for the circle button
          height: MediaQuery.of(context).size.height * .85 / 5,

          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imageurl),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(30),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check if imageUrl is provided, if so show the image, else show the icon
              SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 22, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}