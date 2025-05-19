import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MyLocation {
  double? latitude2;   // nullable로 변경
  double? longitude2;

  Future<bool> getMyCurrentLocation() async {

    // 위치 권한 상태 확인
    var status_position = await Permission.location.status;

    if (!status_position.isGranted) {
      // 권한이 없으면 요청
      var result = await Permission.location.request();
      if (!result.isGranted) {
        print("위치 권한이 필요합니다.");
        return false;  // 권한 거부됨
      }
    }

    // 권한이 있는 경우 위치정보를 받아 저장
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latitude2 = position.latitude;
    longitude2 = position.longitude;

    return true;  // 성공적으로 위치 획득
  }
}
