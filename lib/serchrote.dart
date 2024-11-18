import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'http_connecter.dart';


class Rote{

  final ApiClient ac = ApiClient();
  List<LatLng> _routeDatas = [];
  LatLng _pointA = LatLng(35.701094,139.507086);
  LatLng _pointB = LatLng(34.879299,138.857710);

  List<LatLng> get routeDatas => _routeDatas;

  set pointA(LatLng a) {
    _pointA = a;
  }

  set pointB(LatLng b) {
    _pointB = b;
  }

  String setUrl() {
    String url = "search-route?point=${_pointA.latitude}%2C${_pointA.longitude}&point=${_pointB.latitude}%2C${_pointB.longitude}&profile=car";
    return url;
  }

  Future<String> getPoints() async{

    String points = "null";

    try{
      final data = await ac.request(setUrl());
        //debugPrint('取得したデータ：$data');
        //レスポンスからポリゴンラインを抽出
      final paths = data['paths'] as List<dynamic>;
      if (paths.isNotEmpty) {
        final points = paths[0]['points']; // 最初のpathのpointsを取得
        return points as String;
      } else {
        throw Exception('No paths found in response.');
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

