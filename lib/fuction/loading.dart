import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hackathon/fuction/location.dart';
import 'package:hackathon/fuction/network.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  late double latitude3;
  late double longitude3;
  String? weatherDescription; // 날씨 설명
  double? temperature; // 온도

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    try {
      // MyLocation 클래스 사용하여 위치 가져오기
      MyLocation myLocation = MyLocation();
      await myLocation.getMyCurrentLocation();

      setState(() {
        latitude3 = myLocation.latitude2 ?? 0.0;
        longitude3 = myLocation.longitude2 ?? 0.0;
      });

      // 네트워크 호출
      String weatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude3&lon=$longitude3&appid=$WEATHER_API_KEY&units=metric';

      Network network = Network(weatherUrl);

      // 날씨 데이터 가져오기
      var weatherData = await network.getWeatherData();

      setState(() {
        if (weatherData != null) {
          weatherDescription = weatherData['description'];
          temperature = weatherData['temperature'];
        }
      });

      print('Weather: $weatherDescription');
      print('Temperature: $temperature°C');
    } catch (e) {
      print('Error getting location or weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF49B33), // 배경색
      body: Center(
        child: weatherDescription == null || temperature == null
            ? const SpinKitFadingCircle(
          color: Colors.white, // 로딩 애니메이션 색상
          size: 80.0, // 크기
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Weather: $weatherDescription',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              'Temperature: $temperature°C',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

const WEATHER_API_KEY = 'a25688d777ac6f5231ac22104a17f7a8'; // 발급받은 API 키 입력
