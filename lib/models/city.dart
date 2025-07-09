class City {
  bool isSelected;
  final String city;
  final String country;
  final bool isDefault;

  City({
    required this.isSelected,
    required this.city,
    required this.country,
    required this.isDefault,
  });

  static List<City> citiesList = [
    City(
      isSelected: false,
      city: 'London',
      country: 'United Kingdom',
      isDefault: true,
    ),
    City(
      isSelected: false,
      city: 'New York',
      country: 'United States',
      isDefault: false,
    ),
    City(
      isSelected: false,
      city: 'Tokyo',
      country: 'Japan',
      isDefault: false,
    ),
    City(
      isSelected: false,
      city: 'Paris',
      country: 'France',
      isDefault: false,
    ),
    City(
      isSelected: false,
      city: 'Sydney',
      country: 'Australia',
      isDefault: false,
    ),
  ];

  static List<City> getSelectedCities() {
    return citiesList.where((city) => city.isSelected).toList();
  }
}






















