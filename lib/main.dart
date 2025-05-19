import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hackathon/screen/Start.dart';
import 'package:hackathon/screen/home.dart';
import 'package:hackathon/screen/chat_message.dart';
import 'package:hackathon/screen/Real_time_treffic.dart'; // 실시간 교통 화면
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'firebase_options.dart';

void main() async {
  KakaoSdk.init(
    nativeAppKey: '', // 카카오 네이티브 앱 키 입력
    javaScriptAppKey: '', // 필요 시 자바스크립트 앱 키 입력
  );

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
      onGenerateRoute: (RouteSettings settings) {
        // 소통 채팅 화면
        if (settings.name == '/소통') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null || !args.containsKey('university')) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('대학 이름이 전달되지 않았습니다'),
                ),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (context) => ChatPage(university: args['university']),
          );
        }

        // 실시간 교통 화면
        if (settings.name == '/traffic') {
          final university = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => RealTimeTrafficScreen(university: university),
          );
        }

        // 기본값: null
        return null;
      },
    );
  }
}
