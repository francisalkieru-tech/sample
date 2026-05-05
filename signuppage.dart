import 'package:flutter/material.dart';
import 'personalpage.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Create Account",
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
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Personalize(),
                  ),
                );
              },
              child: const Text("SIGN UP"),
            ),
            
            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}