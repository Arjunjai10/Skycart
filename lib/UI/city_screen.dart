import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final TextEditingController _controller = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  List<String> _recentSearches = [];
  final int _maxRecentSearches = 5;

  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches().then((_) {
      if (_recentSearches.isNotEmpty) {
        _controller.text = _recentSearches.first;
        searchCityWeather(initialLoad: true);
      }
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
        return 'assets/lightcloud.png';
    }
  }

  void searchCityWeather({bool initialLoad = false}) async {
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
        errorMessage = "City not found or network error";
      });
    }
  }

  void _searchRecentCity(String city) {
    _controller.text = city;
    searchCityWeather();
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildWeatherMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
