class WorkoutForm extends StatefulWidget {
  @override
  _WorkoutFormState createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  final TextEditingController _exerciseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Autocomplete<ExerciseModel>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<ExerciseModel>.empty();
            }
            return ExerciseData.getExercises().where((ExerciseModel exercise) {
              return exercise.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          displayStringForOption: (ExerciseModel exercise) => exercise.name,
          onSelected: (ExerciseModel selection) {
            print('You just selected ${selection.name}');
            _exerciseController.text = selection.name; // Optional: update the text controller
          },
        ),
        // Other form fields like setting number of reps, weight, etc.
      ],
    );
  }
}
