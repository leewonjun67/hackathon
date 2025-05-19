import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_user;
import 'package:google_sign_in/google_sign_in.dart';
import 'MyPage.dart';
import 'Start.dart';
import 'package:hackathon/screen/cctv.dart';
import 'package:hackathon/screen/weather.dart';
import 'package:hackathon/fuction/network.dart';
import 'package:hackathon/fuction/location.dart';
class HomeScreen extends StatefulWidget {
  final String university;
  final String url;

  const HomeScreen({Key? key, required this.university, required this.url}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _userName = '';
  String _userProfilePicUrl = '';
  String _userProfilePicUrl1 = '';

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth
      .instance;

  @override
  void initState() {
    super.initState();
    _getGoogleUserInfo();
    _getKakaoUserInfo();
    _getUserInfo();
  }

  void _getKakaoUserInfo() async {
    try {
      kakao_user.User kakaoUser = await kakao_user.UserApi.instance.me();
      String userName = kakaoUser.kakaoAccount?.profile?.nickname ??
          '사용자 이름 없음';
      String userProfilePicUrl = kakaoUser.kakaoAccount?.profile
          ?.thumbnailImageUrl ?? '';

      setState(() {
        _userName = userName;
        _userProfilePicUrl1 = userProfilePicUrl;
      });
    } catch (error) {
      print("카카오톡 사용자 정보 가져오기 실패: $error");
    }
  }

  Future<void> _getGoogleUserInfo() async {
    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        firebase_auth.AuthCredential credential = firebase_auth
            .GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        firebase_auth.UserCredential userCredential = await _firebaseAuth
            .signInWithCredential(credential);
        firebase_auth.User? user = userCredential.user;

        if (user != null) {
          String userName = user.displayName ?? '사용자 이름 없음';
          String userProfilePicUrl = user.photoURL ??
              'https://example.com/default_profile_pic.png';

          _updateUserInfoInFirestore(userName, userProfilePicUrl);

          setState(() {
            _userName = userName;
            _userProfilePicUrl = userProfilePicUrl;
          });
        }
      }
    } catch (error) {
      print("구글 사용자 정보 가져오기 실패: $error");
    }
  }

  void _updateUserInfoInFirestore(String userName,
      String userProfilePicUrl) async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'profilePicUrl': userProfilePicUrl,
        'lastLogin': Timestamp.now(),
      }, SetOptions(merge: true));
    }
  }

  void _getUserInfo() async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? '사용자';
          _userProfilePicUrl = userDoc['profilePicUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      var isKakaoLoggedIn = await _checkKakaoLogin();
      if (isKakaoLoggedIn) {
        await kakao_user.UserApi.instance.logout();
        print('카카오 로그아웃 성공');
      }
    } catch (error) {
      print('카카오 로그아웃 오류: $error');
    }

    GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    if (googleUser != null) {
      await _googleSignIn.signOut();
      print('구글 로그아웃 성공');
    }

    firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _firebaseAuth.signOut();
      print('Firebase 로그아웃 성공');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StartScreen()),
      );
    }
  }

  Future<bool> _checkKakaoLogin() async {
    try {
      final tokenInfo = await kakao_user.UserApi.instance.accessTokenInfo();
      return tokenInfo != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'asset/img/${widget.university}.png',
              height: 50,
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _logout();
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF948BFF)),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _userProfilePicUrl.isNotEmpty
                      ? NetworkImage(_userProfilePicUrl)
                      : (_userProfilePicUrl1.isNotEmpty
                      ? NetworkImage(_userProfilePicUrl1)
                      : AssetImage("asset/img/상명대학교.png") as ImageProvider),
                ),
                accountName: Text(
                  _userName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(widget.university),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('내 정보'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('로그아웃'),
                onTap: () {
                  _logout();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xFF948BFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userProfilePicUrl.isNotEmpty
                        ? NetworkImage(_userProfilePicUrl)
                        : (_userProfilePicUrl1.isNotEmpty
                        ? NetworkImage(_userProfilePicUrl1)
                        : AssetImage("asset/img/상명대학교.png") as ImageProvider),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        widget.university,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            WeatherWidget(),
            SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              children: [
                _buildGridButton(context, '실시간 교통 상황', '/traffic'),
                _buildGridButton(context, '셔틀 시간표', '/shuttle'),
                _buildGridButton(context, '지금 출발한다면?', (context) => CCTVScreen(universityUrl: widget.url)),
                _buildGridButton(
                  context,
                  '소통',
                  '/소통',
                  arguments: {'university': widget.university},
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF948BFF),
        currentIndex: 1,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(university: widget.university, url: widget.url),

              ),
            );
          } else if (index == 2) {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, String title,
      dynamic destination, {Object? arguments}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFA7C7E7),
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: () {
          if (destination is String) {
            Navigator.pushNamed(context, destination, arguments: arguments);
          } else if (destination is WidgetBuilder) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: destination),
            );
          } else if (destination is Widget) {
            // 이 경우는 피하는 게 좋지만, 만약 꼭 인스턴스가 왔다면
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          } else {
            print("잘못된 destination 타입입니다.");
          }
        },
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

const WEATHER_API_KEY = 'a25688d777ac6f5231ac22104a17f7a8';

class WeatherWidget extends StatefulWidget {
  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String temperature = "";
  String condition = "";
  String city = "";
  int? weatherId;
  late double latitude;
  late double longitude;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      MyLocation myLocation = MyLocation();
      await myLocation.getMyCurrentLocation();

      latitude = myLocation.latitude2!;
      longitude = myLocation.longitude2!;

      Network network = Network(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$WEATHER_API_KEY&units=metric&lang=kr',
      ); // 실제 API 주소 및 키로 교체
      var weatherData = await network.getWeatherData();

      if (weatherData != null) {
        setState(() {
          temperature = "${weatherData['temperature'].toString()}°C";
          city = weatherData['cityName'];

          int id = weatherData['weatherId'];
          weatherId = id;

          if ((id >= 200 && id < 600) || (id >= 600 && id < 700)) {
            condition = "지연될 수 있어요 평소보다 빨리 출발해요";
          } else {
            condition = weatherData['description'];
          }
        });
      } else {
        setState(() {
          temperature = "--";
          condition = "정보 없음";
          city = "알 수 없음";
        });
      }
    } catch (e) {
      print("Error fetching weather: $e");
      setState(() {
        temperature = "--";
        condition = "오류 발생";
        city = "알 수 없음";
      });
    }
  }

  IconData getWeatherIcon(int? id) {
    if (id == null) return Icons.wb_sunny;

    if (id >= 200 && id < 600) {
      return Icons.beach_access; // 비 아이콘
    } else if (id >= 600 && id < 700) {
      return Icons.ac_unit; // 눈 아이콘
    } else if (id >= 700 && id < 800) {
      return Icons.cloud; // 안개 아이콘
    } else if (id == 800) {
      return Icons.wb_sunny; // 맑음 아이콘
    } else if (id > 800 && id < 805) {
      return Icons.filter_drama; // 구름 아이콘
    } else {
      return Icons.wb_sunny; // 기본 맑음 아이콘
    }
  }

  Color getBackgroundColor(int? id) {
    if (id == null) return Colors.blueAccent;

    if (id >= 200 && id < 600) {
      return Colors.indigo.shade700; // 비 - 진한 파랑
    } else if (id >= 600 && id < 700) {
      return Colors.lightBlue.shade200; // 눈 - 연한 파랑
    } else if (id >= 700 && id < 800) {
      return Colors.grey.shade500; // 안개 - 회색
    } else if (id == 800) {
      return Colors.orangeAccent; // 맑음 - 주황빛
    } else if (id > 800 && id < 805) {
      return Colors.blueGrey; // 구름 - 청회색
    } else {
      return Colors.blueAccent; // 기본
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WeatherScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: getBackgroundColor(weatherId),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(getWeatherIcon(weatherId), size: 40, color: Colors.white),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.isEmpty ? "로딩중..." : city,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  temperature.isEmpty ? "로딩중..." : temperature,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 4),
                Text(
                  condition.isEmpty ? "로딩중..." : condition,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}