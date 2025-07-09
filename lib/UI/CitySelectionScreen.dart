import 'package:flutter/material.dart';
import '../models/city.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  List<City> cities = City.citiesList;
  final UserService _userService = UserService();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Cities"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];
          return ListTile(
            title: Text('${city.city}, ${city.country}'),
            trailing: Checkbox(
              value: city.isSelected,
              onChanged: (val) {
                setState(() {
                  cities[index].isSelected = val ?? false;
                });
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
            setState(() => isLoading = true);

            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final selectedCities = cities
                  .where((city) => city.isSelected)
                  .map((city) => city.city)
                  .toList();

              if (selectedCities.isEmpty) {
                selectedCities.add('London');
              }

              await _userService.updateSelectedCities(
                user.uid,
                selectedCities,
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              );
            }
          },
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text("Continue"),
        ),
      ),
    );
  }
}