import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/constants.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/weather_item.dart';
import 'detail_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Constants myConstants = Constants();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  double temperature = 0;
  double maxTemp = 0;
  String weatherStateName = '';
  int humidity = 0;
  double windSpeed = 0;
  String currentDate = '';
  String weatherIcon = '';
  String location = '';
  String country = '';
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> forecastList = [];

  // Map weather conditions to local asset images
  // final Map<String, String> weatherIcons = {
  //   'Clear': 'assets/clear.png',
  //   'Clouds': 'assets/lightcloud.png',
  //   'Rain': 'assets/lightrain.png',
  //   'Heavy Rain': 'assets/heavyrain.png',
  //   'Thunderstorm': 'assets/thunderstorm.png',
  //   'Drizzle': 'assets/showers.png',
  //   'Snow': 'assets/snow.png',
  //   'Sleet': 'assets/sleet.png',
  //   'Hail': 'assets/hail.png',
  //   'Mist': 'assets/lightcloud.png',
  //   'Fog': 'assets/lightcloud.png',
  //   'Haze': 'assets/lightcloud.png',
  //   'Smoke': 'assets/lightcloud.png',
  //   'Dust': 'assets/lightcloud.png',
  //   'Sand': 'assets/lightcloud.png',
  //   'Ash': 'assets/lightcloud.png',
  //   'Squall': 'assets/thunderstorm.png',
  //   'Tornado': 'assets/thunderstorm.png',
  // };
  final Map<String, String> weatherIcons = {
    'Clear': 'assets/clear.png',
    'Clouds': 'assets/showers.png',
    'Rain': 'assets/lightrain.png',
    'Heavy Rain': 'assets/heavyrain.png',
    'Snow': 'assets/snow.png',
    'Thunderstorm': 'assets/thunderstorm.png',
    'Drizzle': 'assets/lightrain.png', // Using light rain for drizzle
    'Mist': 'assets/lightcloud.png',
    'Fog': 'assets/lightcloud.png',
    'Haze': 'assets/lightcloud.png',
    'Smoke': 'assets/lightcloud.png',
    'Dust': 'assets/lightcloud.png',
    'Sand': 'assets/lightcloud.png',
    'Ash': 'assets/lightcloud.png',
    'Squall': 'assets/heavyrain.png',
    'Tornado': 'assets/thunderstorm.png',
  };


  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final weatherData = await _weatherService.fetchCurrentWeather(position);
      final forecastData = await _weatherService.fetch5DayForecast(position);

      setState(() {
        temperature = weatherData['main']['temp'];
        maxTemp = weatherData['main']['temp_max'];
        weatherStateName = weatherData['weather'][0]['main'];
        humidity = weatherData['main']['humidity'];
        windSpeed = weatherData['wind']['speed'];
        location = weatherData['name'];
        country = weatherData['sys']['country'] ?? '';
        weatherIcon = weatherData['weather'][0]['icon'];
        currentDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
        forecastList = _processForecastData(forecastData);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getFriendlyErrorMessage(e);
      });
    }
  }

  List<dynamic> _processForecastData(List<dynamic> forecastData) {
    Map<String, dynamic> dailyForecast = {};
    for (var item in forecastData) {
      final date = item['dt_txt'].split(' ')[0];
      if (!dailyForecast.containsKey(date)) {
        dailyForecast[date] = item;
      }
    }
    return dailyForecast.values.toList();
  }

  String _getFriendlyErrorMessage(dynamic e) {
    if (e.toString().contains('Network error')) {
      return 'Internet connection failed';
    } else if (e.toString().contains('Location services')) {
      return 'Please enable location services';
    } else if (e.toString().contains('permissions')) {
      return 'Location permissions required';
    } else {
      return 'Failed to load weather data';
    }
  }

  String _getLocalWeatherIcon(String weatherCondition) {
    String normalizedCondition = weatherCondition[0].toUpperCase() + weatherCondition.substring(1).toLowerCase();
    print("🔍 Normalized condition: $normalizedCondition");

    if (weatherIcons.containsKey(normalizedCondition)) {
      print("Matched: ${weatherIcons[normalizedCondition]}");
      return weatherIcons[normalizedCondition]!;
    }

    final lower = weatherCondition.toLowerCase();
    print("Fallback triggered for: $lower");

    if (lower.contains('thunder')) return 'assets/thunderstorm.png';
    if (lower.contains('heavy') || lower.contains('shower')) return 'assets/heavyrain.png';
    if (lower.contains('rain') || lower.contains('drizzle')) return 'assets/lightrain.png';
    if (lower.contains('cloud')) return 'assets/showers.png';
    if (lower.contains('snow') || lower.contains('sleet')) return 'assets/snow.png';

    return 'assets/showers.png';
  }



  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchWeatherData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/sun (1).png', width: 60, height: 60),
              ),
              Row(
                children: [
                  Image.asset('assets/pin.png', width: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$location, $country',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              currentDate,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Container(
              width: size.width,
              height: 200,
              decoration: BoxDecoration(
                color: myConstants.primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: myConstants.primaryColor.withOpacity(.5),
                    offset: const Offset(5, 30),
                    blurRadius: 10,
                    spreadRadius: -10,
                  )
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -40,
                    left: 20,
                    child: Image.asset(
                      _getLocalWeatherIcon(weatherStateName),
                      width: 150,
                      height: 150,
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: Text(
                      weatherStateName,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            temperature.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Text(
                          '°',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  WeatherItem(
                    text: 'Wind',
                    value: windSpeed.toInt(),
                    unit: 'km/h',
                    imageUrl: 'assets/windspeed.png', // Updated asset name
                  ),
                  WeatherItem(
                    text: 'Humidity',
                    value: humidity,
                    unit: '%',
                    imageUrl: 'assets/humidity.png',
                  ),
                  WeatherItem(
                    text: 'Max Temp',
                    value: maxTemp.toInt(),
                    unit: '°C',
                    imageUrl: 'assets/max-temp.png',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Next ${forecastList.length} Days',
                  style: TextStyle(
                    fontSize: 18,
                    color: myConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Update your forecast list view with this improved version
            SizedBox(
              height: 180, // Increased height for better spacing
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecastList.length,
                itemBuilder: (context, index) {
                  final forecast = forecastList[index];
                  final date = DateTime.parse(forecast['dt_txt']);
                  final dayName = index == 0 ? 'Today' : DateFormat('EEE').format(date);
                  final temp = forecast['main']['temp'];
                  final minTemp = forecast['main']['temp_min'];
                  final weather = forecast['weather'][0];
                  final weatherCondition = weather['main'];
                  final localIcon = _getLocalWeatherIcon(weatherCondition);
                  final description = weather['description'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            forecastData: forecastList,
                            selectedIndex: index,
                            location: location,
                            country: country,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100, // Wider container for better content display
                      margin: EdgeInsets.only(
                        right: 20,
                        left: index == 0 ? 0 : 0, // No extra left margin
                      ),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? myConstants.primaryColor.withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: index == 0
                              ? myConstants.primaryColor
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Day name
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: index == 0
                                    ? myConstants.primaryColor
                                    : Colors.black,
                              ),
                            ),

                            // Weather icon with description
                            Column(
                              children: [
                                Image.asset(
                                  localIcon,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.cloud,
                                    size: 40,
                                    color: index == 0
                                        ? myConstants.primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: index == 0
                                        ? myConstants.primaryColor
                                        : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),

                            // Temperature range
                            Column(
                              children: [
                                Text(
                                  "${temp.toStringAsFixed(0)}°",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? myConstants.primaryColor
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  "${minTemp.toStringAsFixed(0)}°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: index == 0
                                        ? myConstants.primaryColor.withOpacity(0.7)
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}