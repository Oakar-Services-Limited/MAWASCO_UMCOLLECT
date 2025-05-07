// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/pages/home.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:kiambu_umcollect/pages/login.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  bool permission = false;
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final status = await Permission.location.status;
    setState(() => permission = status.isGranted);

    if (permission) {
      // Add 3 second delay before proceeding
      await Future.delayed(const Duration(seconds: 3));
      _proceedToApp();
    }
  }

  Future<void> _proceedToApp() async {
    setState(() => isLoading = true);
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => decoded["error"] == "Invalid token"
                  ? const Login()
                  : const Home()),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() => permission = status.isGranted);

    if (status.isGranted) {
      _proceedToApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UM Collect',
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0288D1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFE3F2FD),
                    Color(0xFFBBDEFB),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Hero(
                                tag: 'logo',
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 180,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                "Mathira Water and Sanitation Company",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  color: const Color(0xff0288D1),
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xff0288D1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "UM Collect",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff0288D1),
                                  ),
                                ),
                              ),
                              if (!permission) ...[
                                const SizedBox(height: 48),
                                ElevatedButton.icon(
                                  onPressed: requestLocationPermission,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff0288D1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  icon: const Icon(Icons.location_on_rounded),
                                  label: const Text(
                                    'Enable Location Access',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Powered by Oakar Services",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: LoadingAnimationWidget.horizontalRotatingDots(
                    color: const Color(0xff0288D1),
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
