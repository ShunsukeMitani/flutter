import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart'; // flutterfire configureで生成されたファイル
import 'login_screen.dart';
import 'home_screen.dart';

// バックグラウンドで通知を受け取った時の処理
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("バックグラウンド通知を受信: ${message.messageId}");
}

// 通知チャンネル設定 (Android用)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // バックグラウンドメッセージハンドラの登録
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 通知設定 (Android)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 通知設定 (iOS/Android)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Run For Money',
      theme: ThemeData.dark(), // ゲームの雰囲気に合わせてダークモード
      home: const AuthCheck(), // ログイン状態チェックへ
    );
  }
}

// ログイン状態とユーザー情報をチェックして振り分ける
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Future<Map<String, dynamic>?> _fetchUserProfile(String uid) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('games')
          .doc('game_001')
          .collection('players')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("User fetch error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. ログインしていない -> ログイン画面へ
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. ログインしている -> Firestoreから情報を取得してホームへ
        User user = snapshot.data!;
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserProfile(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        "Connecting...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data != null) {
              var data = userSnapshot.data!;
              // データがあればホーム画面へ自動遷移
              return HomeScreen(
                myRole: data['role'] ?? 'RUNNER',
                myName: data['name'] ?? 'Unknown',
                // 自動ログイン時は一旦OFF（必要なら設定画面でONにする運用）
                isSecureMode: false,
              );
            }

            // ユーザーデータが見つからない場合はログイン画面へ
            return const LoginScreen();
          },
        );
      },
    );
  }
}
