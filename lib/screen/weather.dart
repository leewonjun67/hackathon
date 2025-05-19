import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:hackathon/fuction/location.dart';
import 'package:hackathon/fuction/network.dart';

const WEATHER_API_KEY = 'a25688d777ac6f5231ac22104a17f7a8';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late double latitude;
  late double longitude;
  String? weatherDescription;
  double? temperature;
  String cityName = "Loading...";
  DateTime currentTime = DateTime.now();
  int? weatherId; // weatherId 추가

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      MyLocation myLocation = MyLocation();
      await myLocation.getMyCurrentLocation();

      setState(() {
        latitude = myLocation.latitude2!;
        longitude = myLocation.longitude2!;
      });

      String weatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$WEATHER_API_KEY&units=metric&lang=kr';

      Network network = Network(weatherUrl);
      var weatherData = await network.getWeatherData();

      if (weatherData != null) {
        setState(() {
          weatherDescription = weatherData['description'];
          temperature = weatherData['temperature'];
          cityName = weatherData['cityName'] ?? "Unknown Location";
          currentTime = DateTime.now();
          weatherId = weatherData['weatherId']; // 여기서 weatherId 저장
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
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
    return Scaffold(
      backgroundColor: getBackgroundColor(weatherId), // 배경색 적용
      appBar: AppBar(
        backgroundColor: getBackgroundColor(weatherId), // 앱바 배경색도 적용 가능
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, {
              'cityName': cityName,
              'temperature': temperature,
              'description': weatherDescription,
            });
          },
        ),
      ),
      body: Center(
        child:
            weatherDescription == null || temperature == null
                ? SpinKitFadingCircle(color: Colors.white, size: 80.0)
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        getWeatherIcon(weatherId), // 아이콘 적용
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cityName,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat('h:mm a - EEEE, d MMM, yyyy').format(currentTime)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        '${temperature!.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          fontSize: 72,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            weatherDescription ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
