import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import 'ExerciseLogPage.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../data/NutritionProvider.dart'; // or adjust path if needed
import '../models/NutritionalInfo.dart';
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding data
  String? goal;
  String? gender;
  String? activityLevel;
  String? workoutSplit;
  int? age;
  int? heightInches;
  int? weightPounds;

  // Controllers
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightFeetController = TextEditingController();
  final TextEditingController heightInchesController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final List<String> goals = ['Lose Weight', 'Gain Weight', 'Maintain'];
  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> activityLevels = [
    'Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'
  ];
  final List<String> splits = [
    'PPL', 'Arnold Split', 'Full Body', 'Bro Split', 'Custom'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    ageController.dispose();
    heightFeetController.dispose();
    heightInchesController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _finishOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        age != null &&
        gender != null &&
        heightInches != null &&
        weightPounds != null &&
        activityLevel != null &&
        goal != null) {

      // Step 1: Calculate maintenance & target calories
      double maintenanceCalories = calculateMaintenanceCalories(
        age: age!,
        gender: gender!,
        heightInches: heightInches!.toDouble(),
        weightPounds: weightPounds!.toDouble(),
        activityLevel: activityLevel!,
      );

      double targetCalories;
      switch (goal!.toLowerCase()) {
        case 'lose weight':
          targetCalories = maintenanceCalories - 500;
          break;
        case 'gain weight':
          targetCalories = maintenanceCalories + 200;
          break;
        default:
          targetCalories = maintenanceCalories;
          break;
      }

      // Step 2: Calculate macros
      final int protein = ((targetCalories * 0.30) / 4).round();
      final int carbs = ((targetCalories * 0.45) / 4).round();
      final int fat = ((targetCalories * 0.25) / 9).round();
      final int calories = targetCalories.round();

      // Step 3: Save user profile to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'goal': goal,
        'age': age,
        'gender': gender,
        'heightInches': heightInches,
        'weightPounds': weightPounds,
        'activityLevel': activityLevel,
        'workoutSplit': workoutSplit,
        'onboardingComplete': true,
        'maintenanceCalories': maintenanceCalories.round(),
      }, SetOptions(merge: true));

      // Step 4: Save macros to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('macros')
          .doc('dailyMacros')
          .set({
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      }, SetOptions(merge: true));

      // Step 5: Save to Hive & update NutritionProvider
      final nutritionBox = await Hive.openBox<NutritionalInfo>('nutritionBox');
      final info = NutritionalInfo(
        calories: calories.toString(),
        protein: protein.toString(),
        carbs: carbs.toString(),
        fats: fat.toString(),
      );
      await nutritionBox.put('nutrition', info);

      try {
        final provider = Provider.of<NutritionProvider>(context, listen: false);
        provider.loadNutritionalInfo(); // refresh from Hive
      } catch (e) {
        print('Provider update failed: $e');
      }

      // Step 6: Navigate to main screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseLogPage()),
        );
      }
    }
  }


  double calculateMaintenanceCalories({
    required int age,
    required String gender,
    required double heightInches,
    required double weightPounds,
    required String activityLevel,
  }) {
    // convert to kg & cm
    final weightKg = weightPounds * 0.453592;
    final heightCm = heightInches * 2.54;

    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very active': 1.9,
    };

    final multiplier = activityMultipliers[activityLevel.toLowerCase()] ?? 1.2;
    return bmr * multiplier;
  }


  Widget _dotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.black : Colors.grey[400],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = (screenWidth * 1.0).clamp(0, screenHeight * 0.9);
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // 0: Intro
                  _OnboardingSlide(
                    title: 'Welcome to Overload!',
                    subtitle: '',
                    image: 'lib/images/onboarding1.png',
                  ),
                  // 1: Features
                  _OnboardingSlide(
                    title: 'Track your calories, workouts, and progress.',
                    subtitle: '',
                    image: 'lib/images/onboarding2.png',
                  ),
                  // 2: Goal
                  _GoalStep(
                    selected: goal,
                    onChanged: (val) => setState(() => goal = val),
                    options: goals,
                  ),
                  // 3: Profile
                  _ProfileStep(
                    ageController: ageController,
                    gender: gender,
                    onGenderChanged: (val) => setState(() => gender = val),
                    genders: genders,
                    heightFeetController: heightFeetController,
                    heightInchesController: heightInchesController,
                    weightController: weightController,
                  ),
                  // 4: Activity & Split
                  _ActivitySplitStep(
                    activityLevel: activityLevel,
                    onActivityChanged: (val) => setState(() => activityLevel = val),
                    activityLevels: activityLevels,
                    workoutSplit: workoutSplit,
                    onSplitChanged: (val) => setState(() => workoutSplit = val),
                    splits: splits,
                  ),
                  // 5: Finish
                  _FinishStep(),
                ],
              ),
            ),
            _dotIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage == 0)
                    TextButton(
                      onPressed: () => _pageController.jumpToPage(5),
                      child: Text('Skip', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    )
                  else if (_currentPage > 0)
                    TextButton(
                      onPressed: _prevPage,
                      child: Text('Back', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    )
                  else
                    SizedBox(width: 60),
                  if (_currentPage < 5)
                    TextButton(
                      onPressed: () {
                        // Validate before next
                        if (_currentPage == 2 && goal == null) return;
                        if (_currentPage == 3) {
                          if (ageController.text.isEmpty ||
                              heightFeetController.text.isEmpty ||
                              heightInchesController.text.isEmpty ||
                              weightController.text.isEmpty ||
                              gender == null) return;
                          age = int.tryParse(ageController.text);
                          int? feet = int.tryParse(heightFeetController.text);
                          int? inches = int.tryParse(heightInchesController.text);
                          if (feet == null || inches == null) return;
                          heightInches = feet * 12 + inches;
                          weightPounds = int.tryParse(weightController.text);
                          if (age == null || heightInches == null || weightPounds == null) return;
                        }
                        if (_currentPage == 4 && (activityLevel == null || workoutSplit == null)) return;
                        _nextPage();
                      },
                      child: Text('Next', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    )
                  else
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text('Finish', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  const _OnboardingSlide({required this.title, required this.subtitle, this.image});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = (screenWidth * 1.0).clamp(0, screenHeight * 0.9);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Image.asset(
                  image!,
                  height: imageSize.toDouble(),
                  width: imageSize.toDouble(),
                  fit: BoxFit.contain,
                ),
              ),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _GoalStep({required this.selected, required this.onChanged, required this.options});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("What's your goal?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            SizedBox(height: 32),
            ...options.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected == opt ? Colors.black : Colors.grey[200],
                  foregroundColor: selected == opt ? Colors.white : Colors.black,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => onChanged(opt),
                child: Text(opt, style: TextStyle(fontSize: 18)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  final TextEditingController ageController;
  final String? gender;
  final ValueChanged<String> onGenderChanged;
  final List<String> genders;
  final TextEditingController heightFeetController;
  final TextEditingController heightInchesController;
  final TextEditingController weightController;
  const _ProfileStep({
    required this.ageController,
    required this.gender,
    required this.onGenderChanged,
    required this.genders,
    required this.heightFeetController,
    required this.heightInchesController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tell us about yourself',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            SizedBox(height: 24),
            MyTextField(
              controller: ageController,
              hintText: 'Age',
              obscureText: false,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: gender,
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => onGenderChanged(val!),
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MyTextField(
                    controller: heightFeetController,
                    hintText: 'Height (ft)',
                    obscureText: false,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MyTextField(
                    controller: heightInchesController,
                    hintText: 'Height (in)',
                    obscureText: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            MyTextField(
              controller: weightController,
              hintText: 'Weight (in pounds)',
              obscureText: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySplitStep extends StatelessWidget {
  final String? activityLevel;
  final ValueChanged<String> onActivityChanged;
  final List<String> activityLevels;
  final String? workoutSplit;
  final ValueChanged<String> onSplitChanged;
  final List<String> splits;
  const _ActivitySplitStep({
    required this.activityLevel,
    required this.onActivityChanged,
    required this.activityLevels,
    required this.workoutSplit,
    required this.onSplitChanged,
    required this.splits,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Activity & Workout Split',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
            SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: activityLevel,
              items: activityLevels
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (val) => onActivityChanged(val!),
              decoration: InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: workoutSplit,
              items: splits
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => onSplitChanged(val!),
              decoration: InputDecoration(
                labelText: 'Workout Split',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.black, size: 80),
            SizedBox(height: 24),
            Text("You're all set!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black)),
            SizedBox(height: 16),
            Text("Let's get started on your fitness journey.",
                style: TextStyle(fontSize: 18, color: Colors.black87), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}