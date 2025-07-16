import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/weather_service.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final TextEditingController _controller = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final Connectivity _connectivity = Connectivity();
  List<String> _recentSearches = [];
  final int _maxRecentSearches = 5;

  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _loadRecentSearches().then((_) {
      if (_recentSearches.isNotEmpty && hasInternet) {
        _controller.text = _recentSearches.first;
        searchCityWeather(initialLoad: true);
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      hasInternet = connectivityResult != ConnectivityResult.none;
    });

    _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        hasInternet = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList('recentSearches') ?? [];
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', _recentSearches);
  }

  void _addRecentSearch(String city) {
    setState(() {
      _recentSearches.removeWhere((item) => item.toLowerCase() == city.toLowerCase());
      _recentSearches.insert(0, city);
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  String _getLocalWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'thunderstorm':
        return 'assets/thunderstorm.png';
      case 'drizzle':
      case 'rain':
        return 'assets/lightrain.png';
      case 'heavy rain':
        return 'assets/heavyrain.png';
      case 'snow':
        return 'assets/snow.png';
      case 'clear':
        return 'assets/clear.png';
      case 'clouds':
        return 'assets/lightcloud.png';
      case 'heavy clouds':
        return 'assets/heavycloud.png';
      default:
        return 'assets/showers.png';
    }
  }

  void searchCityWeather({bool initialLoad = false}) async {
    if (!hasInternet) {
      setState(() {
        errorMessage = "No internet connection";
        isLoading = false;
      });
      return;
    }

    final city = _controller.text.trim();
    if (city.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _weatherService.fetchWeatherByCity(city);
      setState(() {
        weatherData = result;
        isLoading = false;
      });
      if (!initialLoad) {
        _addRecentSearch(city);
      }
    } catch (e) {
      setState(() {
        weatherData = null;
        isLoading = false;
        errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic e) {
    if (!hasInternet) {
      return "No internet connection";
    } else if (e.toString().contains('404')) {
      return "City not found";
    } else {
      return "Failed to load weather data";
    }
  }

  void _searchRecentCity(String city) {
    _controller.text = city;
    searchCityWeather();
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/network_error.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _checkInternetConnection();
              if (hasInternet && _controller.text.isNotEmpty) {
                searchCityWeather();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'City Weather',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[400]!,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[400]!,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[400]!,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet && !isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'City Weather',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.black,
        ),
        body: _buildNoInternetWidget(),
      );
    }

    if (isLoading) {
      return _buildShimmerLoading();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'City Weather',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter city name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) => searchCityWeather(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : () => searchCityWeather(),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Search Weather'),
            ),

            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Searches:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InputChip(
                        label: Text(_recentSearches[index]),
                        onPressed: () => _searchRecentCity(_recentSearches[index]),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _recentSearches.removeAt(index);
                            _saveRecentSearches();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            ],

            if (weatherData != null) ...[
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Image.asset(
                        _getLocalWeatherIcon(weatherData!['weather'][0]['main']),
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${weatherData!['main']['temp'].toStringAsFixed(0)}°C',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${weatherData!['weather'][0]['description']}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildWeatherMetric('Humidity', '${weatherData!['main']['humidity']}%'),
                          _buildWeatherMetric('Wind', '${weatherData!['wind']['speed'].toStringAsFixed(1)} km/h'),
                          _buildWeatherMetric('Feels Like', '${weatherData!['main']['feels_like'].toStringAsFixed(0)}°C'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}