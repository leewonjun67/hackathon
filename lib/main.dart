import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hackathon/screen/Start.dart';
import 'package:hackathon/screen/home.dart';
import 'package:hackathon/screen/chat_message.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'firebase_options.dart';

void main() async {
  KakaoSdk.init(
    nativeAppKey: '', // 카카오 네이티브 앱 키 입력
    javaScriptAppKey: '', // 자바스크립트 앱 키 입력 (필요한 경우)
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
      home: StartScreen(), // 앱 시작화면
      onGenerateRoute: (settings) {
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

        // 다른 라우트도 필요하다면 여기에 추가 가능
        return null;
      },
    );
  }
}
