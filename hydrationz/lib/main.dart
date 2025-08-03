// This file contains the complete source code for a Flutter Hydration Tracker app.
// It features an animated water wave progress bar for a more visually appealing experience.
//
// To use this code, first ensure you have added the 'shared_preferences' package
// to your pubspec.yaml file as described in the instructions above.
//
// Then, copy and paste this entire code block into your main.dart file.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
            side: const BorderSide(color: Color(0xFFFFFFFF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentWaterIntake = 0;
  int _dailyWaterGoal = 2000;
  late SharedPreferences _prefs;

  static const String _keyWaterIntake = 'currentWaterIntake';
  static const String _keyDailyGoal = 'dailyWaterGoal';
  static const String _keyLastResetDay = 'lastResetDay';

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveAnimation = Tween(begin: -pi / 2, end: pi / 2).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    _checkAndResetDailyIntake();

    setState(() {
      _currentWaterIntake = _prefs.getInt(_keyWaterIntake) ?? 0;
      _dailyWaterGoal = _prefs.getInt(_keyDailyGoal) ?? 2000;
    });
  }

  void _checkAndResetDailyIntake() {
    final lastResetDay = _prefs.getInt(_keyLastResetDay) ?? -1;
    final today = DateTime.now().day;

    if (lastResetDay != today) {
      _currentWaterIntake = 0;
      _prefs.setInt(_keyWaterIntake, 0);
      _prefs.setInt(_keyLastResetDay, today);
    }
  }

  void _addWater(int amount) {
    setState(() {
      _currentWaterIntake += amount;
    });
    _saveData();
    if (_currentWaterIntake >= _dailyWaterGoal) {
      _showCompletionMessage();
    }
  }

  void _resetIntake() {
    setState(() {
      _currentWaterIntake = 0;
    });
    _saveData();
  }

  void _saveData() {
    _prefs.setInt(_keyWaterIntake, _currentWaterIntake);
    _prefs.setInt(_keyDailyGoal, _dailyWaterGoal);
  }

  void _showGoalDialog() {
    final TextEditingController controller =
        TextEditingController(text: _dailyWaterGoal.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Water Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter goal in ml (e.g., 2000)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Set'),
              onPressed: () {
                final newGoal = int.tryParse(controller.text);
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    _dailyWaterGoal = newGoal;
                    _saveData();
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCompletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Congratulations! You\'ve reached your daily water goal!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progressPercent = _dailyWaterGoal > 0
        ? (_currentWaterIntake.toDouble() / _dailyWaterGoal.toDouble())
            .clamp(0.0, 1.0)
        : 0.0;

    final bool isGoalCompleted = _currentWaterIntake >= _dailyWaterGoal;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Water Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WaveProgressPainter(
                              progress: progressPercent,
                              wavePhase: _waveController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    if (isGoalCompleted)
                      const Icon(
                        Icons.emoji_events,
                        size: 100,
                        color: Colors.yellowAccent,
                      )
                    else
                      Text(
                        '$_currentWaterIntake ml / $_dailyWaterGoal ml',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addWater(250),
                        child: const Text('+250 ml'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addWater(500),
                        child: const Text('+500 ml'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetIntake,
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showGoalDialog,
                  child: const Text('Set Daily Goal'),
                ),
                const Spacer(),
                const Text(
                  'Developed by Neeraj Singh',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WaveProgressPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double strokeWidth = 20.0;
  final Color backgroundColor = const Color(0xFFE0E0E0).withOpacity(0.3);
  final Color progressColor = Colors.white;
  final Color waveColor = const Color(0xFF2196F3);

  WaveProgressPainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(rect.center, rect.width / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * progress;

    // Draw the progress arc
    canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle, sweepAngle, false,
        progressPaint);

    // Draw the animated wave inside the circle
    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final Path wavePath = Path();
    final double waveHeight = 10;
    final double waterLevel = size.height * (1 - progress);

    wavePath.moveTo(0, waterLevel);
    for (double i = 0; i < size.width; i++) {
      wavePath.lineTo(
          i,
          waterLevel +
              waveHeight * sin(i / size.width * 2 * pi + wavePhase * 2 * pi));
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    // Clip the wave path to the circular shape
    final clipPath = Path()..addOval(rect);
    canvas.clipPath(clipPath);

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
