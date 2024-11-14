/*
import 'dart:developer';
import 'dart:ffi';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'address.dart';

part 'geocoding_provider.g.dart';

@riverpod
class GreocpdongController extends _$GeocodingController{
  late bool isServiceEnabled;
  late LocationPermission permission;
  
  @override
  Future<void> build() async{
    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    
    if(!isServiceEnabled){
      return Future.error('Location services are disabled.');
    }
    
    if(permission == LocationPermission.denied){
        permission = await Geolocator.requestPermission();
        if(permission == LocationPermission.denied){
          return Future.error('Location permissions are denied');
        }
    }
    
    if(permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  // Future<Position> getCurrentPosition() async {
  //   return await Geolocator.getCurrentPosition();
  // }
  //
  // Future<Placemark?> getPlacemarkFromPosition(double latitude,double longitude) async {
  //     final placeMarks = await placemarkFromCoordinates(latitude, longitude);
  //     if(placeMarks.isEmpty) {
  //       print("No placemarks found");
  //       return null;
  //     }
  //     final placeMark = placeMarks[0];
  //     return placeMark;
  // }

  Future<Address?> getCurrentAddress() async {
    final currentPosition = await getCurrentPosition();
    final placeMark = await getPlacemarkFromPosition(currentPosition.latitude, currentPosition.longitude,);

    if(placeMark == null){
      print('Placemark is null');
      return null;
    }

    final address = Address(
      country: placeMark.country ?? '',
      prefecture: placeMark.administrativeArea ?? '',
      city: placeMark.locality ?? '',
      street: placeMark.street ?? '',
    );
    return address;
  }

  Future<Address?> getAddressInfoFromPosition(double latitude, double longitude) async {
    final placeMark = await getPlacemarkFromPosition(latitude, longitude);

    if(placeMark == null){
      print('Placemark is null');
      return null;
    }

    final address = Address(
      country: placeMark.country ?? '',
      prefecture: placeMark.administrativeArea ?? '',
      city: placeMark.locality ?? '',
      street: placeMark.street ?? '',
    );
    return address;
  }
}*/
