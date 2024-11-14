import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


class Rote{

  List<LatLng> _routeDatas = [];
  LatLng _pointA = LatLng(35.701094,139.507086);
  LatLng _pointB = LatLng(34.879299,138.857710);
  final String _url = "https://c9ce-116-82-21-249.ngrok-free.app";

  List<LatLng> get routeDatas => _routeDatas;

  set pointA(LatLng a) {
    _pointA = a;
  }

  set pointB(LatLng b) {
    _pointB = b;
  }

  String setUrl() {
    String url = "$_url/search-route?point=${_pointA.latitude}%2C${_pointA.longitude}&point=${_pointB.latitude}%2C${_pointB.longitude}&profile=car";
    debugPrint(url);
    return url;
  }

  Future<String> getPoints() async{

    String points = "null";

    try{
      final response = await http.get(Uri.parse(setUrl()));
      if(response.statusCode == 200) {
        //通信が成功したら、レスポンスをデコード
        final data = json.decode(response.body);

        //レスポンスからポリゴンラインを抽出
        points = data['paths'][0]['points'];
        return points;
      }
      else {
        debugPrint('Failed to load data: ${response.statusCode}');
        return points;
      }
    }
    catch(e) {
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }

  void decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;

      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      polyline.add(LatLng(latitude, longitude));
    }
    _routeDatas= polyline;
  }
}

