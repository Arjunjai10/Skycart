import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/constants.dart';
import '../services/weather_service.dart';

class DetailPage extends StatelessWidget {
  final List<dynamic> forecastData;
  final int selectedIndex;
  final String location;
  final String country;

  const DetailPage({
    super.key,
    required this.forecastData,
    required this.selectedIndex,
    required this.location,
    required this.country,
  });

  // Helper method to get local weather icon based on weather condition
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

  @override
  Widget build(BuildContext context) {
    final Constants myConstants = Constants();
    final selectedDay = forecastData[selectedIndex];

    // Parse and format date
    final date = DateFormat('EEEE, d MMMM').format(DateTime.parse(selectedDay['dt_txt']));
    final weatherName = selectedDay['weather'][0]['main'];
    final temp = selectedDay['main']['temp'];
    final maxTemp = selectedDay['main']['temp_max'];
    final humidity = selectedDay['main']['humidity'];
    final windSpeed = (selectedDay['wind']['speed'] * 3.6).toStringAsFixed(1); // Convert m/s to km/h
    final iconPath = _getLocalWeatherIcon(weatherName);
    final feelsLike = selectedDay['main']['feels_like'];
    final pressure = selectedDay['main']['pressure']?.toString() ?? 'N/A'; // Handle null pressure

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Details"),
        backgroundColor: myConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Location and date
              Text(
                '$location, $country',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Weather icon
              Image.asset(
                iconPath,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.cloud,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Temperature
              Text(
                "${temp.toStringAsFixed(0)}°C",
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Feels like ${feelsLike.toStringAsFixed(0)}°C",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weatherName,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Weather metrics
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildInfoCard(
                    'Max Temp',
                    "${maxTemp.toStringAsFixed(0)}°C",
                    Icons.thermostat_outlined,
                  ),
                  _buildInfoCard(
                    'Humidity',
                    "$humidity%",
                    Icons.water_drop_outlined,
                  ),
                  _buildInfoCard(
                    'Wind',
                    "$windSpeed km/h",
                    Icons.air_outlined,
                  ),
                  _buildInfoCard(
                    'Pressure',
                    "$pressure hPa",
                    Icons.speed_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}