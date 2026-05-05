import 'package:flutter/material.dart';

class ListPage extends StatefulWidget {
  final String title; 
  final List<String> exercises; 

  const ListPage({
    super.key,
    required this.title,
    required this.exercises,
  });

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  Set<int> completedIndexes = {};
  TextEditingController controller = TextEditingController();
  late List<String> workouts;

  @override
  void initState() {
    super.initState();
    workouts = List.from(widget.exercises);
  }

  void addWorkout() {
    if (controller.text.isNotEmpty) {
      setState(() {
        workouts.add(controller.text);
        controller.clear();
      });
    }
  }

  void toggleWorkout(int index) {
    setState(() {
      if (completedIndexes.contains(index)) {
        completedIndexes.remove(index);
      } else {
        completedIndexes.add(index);
      }
    });
  }

  void deleteWorkout(int index) {
    setState(() {
      workouts.removeAt(index);
      completedIndexes = completedIndexes
          .where((i) => i != index)
          .map((i) => i > index ? i - 1 : i)
          .toSet();
    });
  }

  void finishWorkout() {
    double progress = workouts.isEmpty
        ? 0
        : completedIndexes.length / workouts.length;
    Navigator.pop(context, progress); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Column(
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Add workout",
              hintStyle: const TextStyle(color: Colors.white70),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: addWorkout,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                bool done = completedIndexes.contains(index);
                return ListTile(
                  leading: Checkbox(
                    value: done,
                    onChanged: (_) => toggleWorkout(index),
                    checkColor: const Color.fromARGB(255, 0, 119, 255),
                    fillColor: MaterialStateProperty.all(Colors.grey),
                  ),
                  title: Text(
                    workouts[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        color: Color.fromARGB(255, 255, 0, 0)),
                    onPressed: () => deleteWorkout(index),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Finish Workout",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}