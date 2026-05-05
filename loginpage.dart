import 'package:flutter/material.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personalpage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Hello\nLogin",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                
                String? level = prefs.getString('level');
                String? goal = prefs.getString('goal');
                
                if (level != null && goal != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Homepage(
                        level: level,
                        goal: goal,
                      ),
                    ),
                  );
                } else {
                  // hindi pa personalized → balik sa Personalize
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Personalize(),
                      ),
                  );
                }
              },
              child: const Text("LOGIN"),
            ),
            const SizedBox(height: 20),
            
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text("Don't have an account? Sign Up"),
            )
          ],
        ),
      ),
    );
  }
}