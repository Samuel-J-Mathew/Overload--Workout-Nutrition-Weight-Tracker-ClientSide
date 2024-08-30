import 'package:flutter/material.dart';
import 'package:gymapp/data/workout_data.dart';
import 'package:gymapp/workout_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
  class _HomePageState extends State<HomePage>{

  //text controller
    final newWorkoutNameController = TextEditingController();

  // create a new workout
    void createNewWorkout (){
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("create a new workout"),
            content: TextField(
              controller: newWorkoutNameController,
            ),
            actions: [
              //save button
              MaterialButton(
                  onPressed: save,
                  child: Text ("save"),
              ),
              //cancel button

              MaterialButton(
                onPressed: cancel,
                child: Text ("cancel"),
              ),
            ],
          ),
      );
    }
    // go to workout page
    void goToWorkoutPage(String workoutName){
      Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutPage(
        workoutName: workoutName,
      ), ));
    }

    // save workout
    void save() {
      // get workout name from text controller
      String newWorkoutName = newWorkoutNameController.text;
      // add workout to workoutdata list
      Provider.of<WorkoutData>(context,listen: false).addWorkout(newWorkoutNameController.text);

      //pop dialog box
      Navigator.pop(context);
      clear();
    }

    //cancel
    void cancel() {
      //pop diolog box
      Navigator.pop(context);
      clear();
    }

    //clear controllers
    void clear(){
      newWorkoutNameController.clear();
    }
    @override
    Widget build(BuildContext context) {
      return Consumer<WorkoutData>(
        builder:(context,value , child) =>Scaffold(
          appBar: AppBar(
            title: const Text('Workout Tracker'),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: createNewWorkout,
            child: const Icon(Icons.add),
          ) ,
          body: ListView.builder(
              itemCount: value.getworkoutList().length,
              itemBuilder: (context,index) => ListTile(
                  title: Text(value.getworkoutList()[index].name),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () =>
                      goToWorkoutPage(value.getworkoutList()[index].name) ,
                ),
              ),
          ),
      ),
      );
    }
}
