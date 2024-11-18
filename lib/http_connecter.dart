import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiClient {

  final String _hostUrl = "https://84de-61-215-148-214.ngrok-free.app/";

  // HTTP GETリクエストを送信し、レスポンスを返却するメソッド
  Future<Map<String, dynamic>> request(String url) async {
    try {
      final response = await http.get(Uri.parse(_hostUrl + url));
      // ステータスコードを確認
      debugPrint(response.statusCode.toString());
      if (response.statusCode == 200) {
        // レスポンスボディをJSONとしてデコード
        return jsonDecode(response.body);
      }
      else {
        // エラーレスポンスを投げる
        throw Exception('データの読み込みに失敗しました。 Status code: ${response.statusCode}');
      }
    }
    catch (e) {
      throw Exception('APIサーバとの接続に失敗しました。: $e');// エラーハンドリング
    }
  }
}