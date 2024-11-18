import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert' as convert;

import 'serchrote.dart';                //ルート検索関連ファイルをインポート

//http証明の無視
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async{
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{

  late final _animatedMapController = AnimatedMapController(vsync: this);
  late StreamSubscription<Position> _positionStreamSubscription;
  late StreamSubscription<CompassEvent> _compassStreamSubscription;

  LatLng _currentPosition = const LatLng(35.681236, 139.767125);
  double _currentHeading = 0.0;
  double _targetHeading = 0.0;
  Timer? _timer;
  bool _btnCondition = false;

  List<Marker> addMarkers = [];
  List<Marker> addStores = [];
  final List<bool> _checkboxValues = List<bool>.filled(8, false); // チェックボックスの初期値
  double _currentSize = 0.1;

  final Rote rote = Rote();

  //最初に読み込まれる処理
  @override
  void initState(){
    super.initState();
    _initLocationUpdates();
    _initCompassUpdates();
    _callAPI();
    _setRoteData();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    _compassStreamSubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  //テスト用メソッド
  void _setRoteData() async{
    String points = await rote.getPoints();
    rote.decodePolyline(points);

    //for (var coord in roteData) {
    // print('Latitude: ${coord.latitude}, Longitude: ${coord.longitude}');
    //}
  }

  //位置情報の取得
  void _initLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効かどうか確認
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      return Future.error('位置情報サービスが無効になっています。');
    }

    // 位置情報の権限を確認
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        //権限が拒否された場合
        return Future.error('位置情報の許可が拒否されました。');
      }
    }

    //権限が永久に拒否されている場合
    if(permission == LocationPermission.deniedForever) {
      return Future.error('位置情報の許可は永久に拒否されます。許可をリクエストすることはできません。');
    }

    //リアルタイムで位置情報を取得
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState((){
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _animatedMapController.animateTo(dest:_currentPosition);
    });
  }

  //住所取得
  Future<Placemark?> _getPlacemarkFromPosition(double latitude,double longitude) async {
    final placeMarks = await placemarkFromCoordinates(latitude, longitude);
    if (placeMarks.isEmpty) {
      return null;
    }
    final placeMark = placeMarks[0];
    return placeMark;
  }

  Future<String> getAddressFromPosition(double latitude, double longitude) async {
    final placeMark = await _getPlacemarkFromPosition(latitude, longitude);
    if (placeMark == null) {
      return 'No placemark found';
    }

    String address = '';
    address = placeMark.street!;
    return address;
  }

  //向いている方向を取得して代入
  void _initCompassUpdates() {
    _compassStreamSubscription = FlutterCompass.events!.listen((CompassEvent event) {
      double heading = event.heading!;
      if (event.heading == null) return;
      _targetHeading = heading;
      //_currentHeading = event.heading!;

    });

   //タイマーを設定して定期的に回転を更新
    _timer = Timer.periodic(const Duration(milliseconds: 50),(Timer T) {
      setState(() {
        _currentHeading = _lerpAngle(_currentHeading, _targetHeading, 0.08);
        if(_btnCondition) {
          _animatedMapController.mapController.rotate(-_currentHeading);
        }
      });
    });
  }

  // 線形補間を使用して角度をスムーズに遷移
  double _lerpAngle(double start, double end, double t) {

    double difference = end - start;
    if (difference > 180.0)       {end -= 360.0;}
    else if (difference < -180.0) {end += 360.0;}

    return start + (end - start) * t;
  }

  //マーカー表示処理
  void _addMarker(LatLng latlng) {
    setState((){
      addMarkers.clear();
      addMarkers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: latlng,
          child: GestureDetector(
            onTap:() {
              _animatedMapController.animateTo(dest: latlng);
              _showAlert(latlng);
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.orange,
              size: 45,
            ),
          ),
          rotate: true,
        ),

      );
    });
  }

  //http通信
  void _callAPI() async{
    var url = Uri.https('cf4c-61-215-148-214.ngrok-free.app','/api1/qs/');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> dataList = convert.jsonDecode(response.body) as List<dynamic>;
      print(dataList.length);
      for(int i=0; i<dataList.length; i++){
        LatLng latlng2 = LatLng(double.parse(dataList[i]['store_lat']),double.parse(dataList[i]['store_long']));
        print('latlng${latlng2}');
        setState(() {
          addStores.add(
            Marker(
              width: 30.0,
              height: 30.0,
              point: latlng2,
              child: const Icon(
                Icons.location_on,
                color: Colors.brown,
                size: 50,
              ),
              rotate: false,
            ),
          );
        });
      }
    }
    else {
      print('❌ Request failed with status: ${response.statusCode}.');
    }
  }

  //緯度経度表示処理
  Future<void> _showAlert(LatLng latlng) async{
    String address = await getAddressFromPosition(latlng.latitude,latlng.longitude);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ピンの位置'),
        content: Text('''
        緯度：${latlng.latitude.toStringAsFixed(4)}
        経度：${latlng.longitude.toStringAsFixed(4)}
        住所：$address
        '''),
        actions: <Widget>[
          TextButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  //現在位置表示ボタン処理
  void _showCurrentPosition(LatLng point, double zoom) {
    setState(() {
      if(point.latitude == _currentPosition.latitude &&
              point.longitude == _currentPosition.longitude){

        _btnCondition = !_btnCondition;

        if(_btnCondition) {_animatedMapController.mapController.rotate(-_currentHeading);}
        else              {_animatedMapController.mapController.rotate(0);}

      }
      else{
        zoom = zoom<=16.0? 16.0 : zoom;
        _animatedMapController.animateTo(dest:_currentPosition, zoom: zoom);
      }
    });
  }

  //検索メニュースナップ処理
  void _snapToNearestSize(DraggableScrollableController controller, double size) {
    double snapSize;

    // 10%, 50%, 90%のいずれかにスナップ
    if ((size - 0.1).abs() < (size - 0.5).abs() && (size - 0.1).abs() < (size - 0.9).abs()) {
      snapSize = 0.1; // 10%にスナップ
    } else if ((size - 0.5).abs() < (size - 0.1).abs() && (size - 0.5).abs() < (size - 0.9).abs()) {
      snapSize = 0.5; // 50%にスナップ
    } else {
      snapSize = 0.9; // 90%にスナップ
    }

    // スナップ位置にアニメーションで移動
    controller.animateTo(
      snapSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }






  @override
  Widget build(BuildContext context) {
    DraggableScrollableController _controller = DraggableScrollableController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('リアルタイム位置情報',),
      ),

      /*body: FlutterMap(
        mapController: _animatedMapController.mapController,
        options:  MapOptions(
          initialCenter: _currentPosition,
          initialZoom: 16.0,
          maxZoom: 20.0,
          minZoom: 2.0,
          initialRotation: _btnCondition? _currentHeading:0.0,
          onTap:(tapPosition,point) {
            _addMarker(point);
          },
        ),

        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: _currentPosition,
                child: Transform.rotate(
                  angle: _currentHeading *  pi / 180,
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.cyan,
                    size: 45,
                  ),
                )
              ),
            ],
          ),
          MarkerLayer(markers: addMarkers),
          MarkerLayer(markers: addStores),
        ],
      ),*/

      body: Stack(
        children: [
          // Mapの描画
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 16.0,
              maxZoom: 20.0,
              minZoom: 2.0,
              initialRotation: _btnCondition ? _currentHeading : 0.0,
              onTap: (tapPosition, point) {
                _addMarker(point);
              },
            ),

            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',),

              MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _currentPosition,
                      child: Transform.rotate(
                        angle: _currentHeading *  pi / 180,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.cyan,
                          size: 45,
                        ),
                      ),
                    ),
                  ]
              ),
              MarkerLayer(markers: addMarkers),
              MarkerLayer(markers: addStores),
              
              //ルート案内用の線追加
              PolylineLayer(
                  polylines: [
                    Polyline(
                      points:rote.routeDatas,
                      strokeWidth: 12.0,
                      color: Colors.cyan.withOpacity(0.5),
                    ),
                  ],
              ),
            ],
          ),

          // DraggableScrollableSheet の追加
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              // シートがドラッグされていない場合にのみスナップ
              if (notification.extent != notification.minExtent &&
                  notification.extent != notification.maxExtent) {
                _snapToNearestSize(_controller, notification.extent);
              }
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: _currentSize, // 初期の表示サイズ（画面の10%）
              minChildSize: 0.1, // 最小サイズ（10%）
              maxChildSize: 0.9, // 最大サイズ（90%）
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          controller: scrollController,
                          crossAxisCount: 2, // 列の数
                          children: List.generate(8, (index) {
                            return CheckboxListTile(
                              title: Text('チェックボックス ${index + 1}'),
                              value: _checkboxValues[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  _checkboxValues[index] = value!;
                                });
                              },
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCurrentPosition(
              _animatedMapController.mapController.camera.center,
              _animatedMapController.mapController.camera.zoom
          );
        },
        child: _btnCondition? const Icon(Icons.explore) : const Icon(Icons.location_on),
      ),


    );
  }
}
