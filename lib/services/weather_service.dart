import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String apiKey = 'e5c4ac89fee13c05693c8d604f1d9232';
  final LocationService _locSvc = LocationService();

  Future<Map<String, dynamic>> fetchCurrentWeather(Position position) async {
    return _makeRequest(
        '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey');
  }

  Future<List<dynamic>> fetch5DayForecast(Position position) async {
    final data = await _makeRequest(
        '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey');
    return data['list'];
  }

  Future<Map<String, dynamic>> fetchWeatherByCity(String city) async {
    return _makeRequest('$_baseUrl/weather?q=$city&units=metric&appid=$apiKey');
  }

  Future<Map<String, dynamic>> _makeRequest(String url) async {
    try {
      final response = await http
          .get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 404) {
        throw Exception('City not found');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  String getWeatherAsset(String mainCondition) {
    switch (mainCondition) {
      case 'Clear':
        return 'assets/clear.png';
      case 'Clouds':
        return 'assets/lightcloud.png';
      case 'Rain':
        return 'assets/lightrain.png';
      case 'Heavy Rain':
        return 'assets/heavyrain.png';
      case 'Thunderstorm':
        return 'assets/thunderstorm.png';
      case 'Snow':
        return 'assets/snow.png';
      default:
        return 'assets/lightcloud.png';
    }
  }

  Future<void> fetchInitialWeather() async {
    try {
      final position = await _locSvc.getCurrentPosition();
      final weather = await fetchCurrentWeather(position);
      print("🌤️ Initial weather loaded for ${weather['name']}");
    } catch (e) {
      print("⚠️ Error loading initial weather: $e");
    }
  }
}