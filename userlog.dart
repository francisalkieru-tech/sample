import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'signuppage.dart';

class UserLog extends StatelessWidget {
  const UserLog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1F44),
              Color(0xFF0D2A66),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Logo + App Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.fitness_center, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Workout Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Welcome Text
              const Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // SIGN IN BUTTON
              SizedBox(
                width: 220,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text("LOG IN"),
                ),
              ),

              const SizedBox(height: 15),

              // SIGN UP BUTTON
              SizedBox(
                width: 220,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },
                  child: const Text("SIGN UP"),
                ),
              ),

              const SizedBox(height: 30),

              // Continue with text
              const Text(
                "Continue with",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 15),

              // Social Icons (basic only)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.facebook, color: Colors.blue),
                  SizedBox(width: 20),
                  Icon(Icons.g_mobiledata, color: Colors.red),
                  SizedBox(width: 20),
                  Icon(Icons.apple, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}