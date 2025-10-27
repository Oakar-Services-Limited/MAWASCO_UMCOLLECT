// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.data}');

  // For background notifications, you can show system notification here
  // This will be handled by the system when app is in background
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

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

  // Global key for showing notifications from anywhere
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
    _setupNotifications();
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

      // Check if token is null or empty
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        }
        return;
      }

      var decoded = parseJwt(token);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => decoded["error"] == "Invalid token"
                  ? const Login()
                  : const Home()),
        );
      }
    } catch (e) {
      print("Error parsing token: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
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

  Future<void> _setupNotifications() async {
    try {
      // Request notification permissions
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token (will be registered after login)
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Token will be registered after user logs in
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Set up foreground message handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('FOREGROUND MESSAGE RECEIVED');
        print('Foreground Message Data: ${message.data}');

        // Show system notification even when app is in foreground
        if (message.data.isNotEmpty) {
          _showSystemNotification(message);
        }

        // Handle navigation based on target
        _handleNotificationNavigation(message.data);
      });

      // Handle when app is opened from terminated state
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from terminated state with message:');
          print('Initial Message Data: ${message.data}');
          _handleNotificationNavigation(message.data);
        }
      });

      // Handle when app is opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background state with message:');
        print('Message Data: ${message.data}');
        _handleNotificationNavigation(message.data);
      });

      // Initialize local notifications
      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          if (response.payload != null) {
            try {
              final data = json.decode(response.payload!);
              _handleNotificationNavigation(data);
            } catch (e) {
              print('❌ Error parsing notification payload: $e');
            }
          }
        },
      );

      // Token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        // Token will be re-registered after user logs in again
      });
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }

  void _showSystemNotification(RemoteMessage message) {
    try {
      // Create a system notification that matches the FCM message
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'incidents',
        'Incident Notifications',
        channelDescription: 'Notifications for new incidents assigned',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xff0288D1),
        icon: '@drawable/logo',
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      _flutterLocalNotificationsPlugin.show(
        0, // notification id
        '🚨 New Incident Assigned',
        'Type: ${message.data['incidentType']} | Location: ${message.data['location']}',
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );

      print('✅ System notification shown successfully');
      print(
          '📱 Notification: ${message.data['incidentType']} - ${message.data['location']}');
    } catch (e) {
      print('❌ Error showing system notification: $e');
      // Fallback to simple alert if system notification fails
      _showSimpleAlert(message.data);
    }
  }

  void _showSimpleAlert(Map<String, dynamic> data) {
    try {
      // Use a more reliable way to show the dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (mounted && context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false, // User must tap a button
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('🚨 New Incident Assigned'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type: ${data['incidentType'] ?? 'Unknown'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Location: ${data['location'] ?? 'Unknown'}'),
                      SizedBox(height: 4),
                      Text('ID: ${data['incidentId'] ?? 'Unknown'}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleNotificationNavigation(data);
                      },
                      child: Text('View Details'),
                    ),
                  ],
                );
              },
            );
            print('✅ Alert dialog shown successfully');
          } else {
            print('⚠️ Cannot show alert dialog - context not available');
          }
        } catch (e) {
          print('❌ Error showing alert dialog: $e');
        }
      });
    } catch (e) {
      print('❌ Error in _showSimpleAlert: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final target = (data['target'] ?? '').toString().toUpperCase().trim();
    print('Target value: $target');

    if (target == 'INCIDENT') {
      // Handle incident notification
      print('Incident notification received: ${data['incidentId']}');
      // You can navigate to a specific page here if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UM Collect',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0288D1),
          brightness: Brightness.light,
        ),
        textTheme:
            Theme.of(context).textTheme, // Use default Flutter text theme
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
