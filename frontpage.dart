import 'package:flutter/material.dart';
import 'userlog.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          Image.asset(
            "assets/38d70711789e7380cc4616afb6419918.jpg",
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.black.withOpacity(0.5),
          ),
           Positioned(
            top: 60, left: 0, right: 0,
            child: const Text(
              "Workout Tracker",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 1, 154, 255),
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 80, 30, 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Get Fit not Fat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(flex: 1),
                const Text(
                  "Push Your Limits",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.all(0),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const UserLog()),
                      );
                    },
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 8, 0, 255),
                            Color.fromARGB(255, 0, 217, 255),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      child: const Center(
                        child: Text(
                          "Get Started",
                          style: TextStyle(fontSize: 18, fontWeight: .w600, color: Colors.white,),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}