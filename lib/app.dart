import 'package:material_ui/material_ui.dart';

import 'core/colors.dart';
import 'presentation/screens/splash/splash_screen.dart';

class EliteWaveCabsApp extends StatelessWidget {
  const EliteWaveCabsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elite Wave Cabs',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
        ),
        useMaterial3: true,
      ),

      // FIXED: Splashscreen -> SplashScreen
      home: const SplashScreen(),
    );
  }
}