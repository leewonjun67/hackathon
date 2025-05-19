import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class RealTimeTrafficScreen extends StatelessWidget {
  final String university;

  RealTimeTrafficScreen({required this.university});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF948BFF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60, bottom: 16, left: 20, right: 20),
            color: Color(0xFF948BFF), // 상단 노란색
            child: Center(
              child: Column(
                children: [
                  Text(
                    '$university 실시간 교통',
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 32,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Image.asset(
                    'asset/img/transport_10890745.png',
                    height: 36,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 360,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white, // 하얀색 내부 박스
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('university')
                      .doc(university)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Color(0xFFF5F5F5)));
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(
                          child: Text(
                            '정류장 정보를 찾을 수 없습니다.',
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              color: Colors.black87,
                            ),
                          ));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final stops = data['stops'] as List<dynamic>;

                    return ListView.builder(
                      itemCount: stops.length,
                      itemBuilder: (context, index) {
                        final stop = stops[index];
                        return TrafficWidget(
                          stationName: stop['name'],
                          stationId: stop['stationId'],
                          busRoutes: (stop['busRoutes'] as List).map((e) => e.toString()).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrafficWidget extends StatefulWidget {
  final String stationId;
  final List<String> busRoutes;
  final String stationName;

  TrafficWidget({required this.stationId, required this.busRoutes, required this.stationName});

  @override
  _TrafficWidgetState createState() => _TrafficWidgetState();
}

class _TrafficWidgetState extends State<TrafficWidget> {
  Map<String, List<int>> groupedInfo = {};
  bool isLoading = false;
  bool expanded = false;

  Future<void> fetchBusArrival() async {
    setState(() {
      isLoading = true;
    });

    final serviceKey = 'fSDsRzF6m2YI1GxIiMbPPkAyAZbMY1qT7YFZq6q69pfnOGItdey%2Bl%2FvQys0Y3XkYx7RNBkGzXKfwUxw%2BEbAnMA%3D%3D';
    final cityCode = '34010';
    final nodeId = widget.stationId;

    final url = Uri.parse(
        'http://apis.data.go.kr/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList'
            '?serviceKey=$serviceKey&cityCode=$cityCode&nodeId=$nodeId&numOfRows=10&pageNo=1&_type=json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final itemData = data['response']['body']['items']['item'];
        final items = itemData is List ? itemData : [itemData];

        final Map<String, List<int>> grouped = {};

        for (var item in items) {
          final route = item['routeno']?.toString() ?? '알 수 없음';
          final timeInSec = item['arrtime'] ?? 0;
          final time = (int.tryParse(timeInSec.toString()) ?? 0) ~/ 60;

          if (widget.busRoutes.contains(route)) {
            grouped.putIfAbsent(route, () => []).add(time);
          }
        }

        setState(() {
          groupedInfo = grouped;
          isLoading = false;
        });
      } else {
        throw Exception('API 응답 실패');
      }
    } catch (e) {
      print('API 에러: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleExpanded() async {
    if (!expanded) await fetchBusArrival();
    setState(() {
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white, // 내부는 그대로 흰색 유지
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('정류장',
                            style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 12, color: Colors.grey[600])),
                        SizedBox(height: 4),
                        Text(
                          widget.stationName,
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 26,
                      color: Colors.deepPurple,
                    ),
                    onPressed: toggleExpanded,
                  )
                ],
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : groupedInfo.isEmpty
                    ? Text('도착 예정 버스가 없습니다.',
                    style: TextStyle(fontFamily: 'BlackHanSans'))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedInfo.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key}번 버스',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text(entry.value.map((t) => '$t분 후').join(', '),
                            style: GoogleFonts.poppins(fontSize: 13)),
                        SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
