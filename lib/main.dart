import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  String location = 'San Francisco';
  int woeid = 2487956;
  String weather = 'clear';
  String abbrevation = '';
  String errorMessage = '';

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  bool isfetchLocationDay = true;
  bool isSearchIcon = true;

  var minTemperatureForecast = new List(7);
  var maxTemperatureForecast = new List(7);
  var abbreviationForecast = new List(7);

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('images/$weather.png'),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.dstATop)),
        ),
        child: temperature == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: isSearchIcon
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSearchIcon = false;
                                });
                              },
                              child: Icon(
                                Icons.search,
                                size: 36.0,
                              ),
                            )
                          : Container(
                              width: 300,
                              child: TextField(
                                onSubmitted: (String input) {
                                  onTextFieldSubmitted(input);
                                  setState(() {
                                    isfetchLocationDay = true;
                                    isSearchIcon = true;
                                  });
                                },
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search another location...',
                                  hintStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          _getCurrentLocation();
                        },
                        child: Icon(
                          Icons.location_on_sharp,
                          size: 36.0,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: Platform.isAndroid ? 15.0 : 20.0,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/png/${abbrevation}.png',
                            width: 100.0,
                          ),
                        ),
                        Center(
                          child: Text(
                            temperature.toString() + ' ℃',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60.0,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            location,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 200.0,
                      child: isfetchLocationDay
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                //return Text('Item ${index + 1}');
                                return forecastElement(
                                    index,
                                    abbreviationForecast[index],
                                    minTemperatureForecast[index],
                                    maxTemperatureForecast[index]);
                              },
                              itemCount: 7,
                              scrollDirection: Axis.horizontal,
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];
      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage =
            "Sorry, we don't have data about this city.\nTry another one";
      });
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidated_weather = result['consolidated_weather'];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data['the_temp'].round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbrevation = data['weather_state_abbr'];
    });
  }

  void fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString());
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data['min_temp'].round();
        maxTemperatureForecast[i] = data['max_temp'].round();
        abbreviationForecast[i] = data['weather_state_abbr'];
      });
    }
    setState(() {
      isfetchLocationDay = false;
    });
  }

  Widget forecastElement(
      daysFromNow, abbreviation, minTemperature, maxTemperature) {
    var now = new DateTime.now();
    var oneDayFromNow = now.add(new Duration(days: daysFromNow));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 5.0),
          child: Column(
            children: [
              Text(
                new DateFormat.E().format(oneDayFromNow),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              Text(
                new DateFormat.MMMd().format(oneDayFromNow),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              Image.network(
                'https://www.metaweather.com/static/img/weather/png/${abbrevation}.png',
                width: 50.0,
              ),
              Text(
                'High: ' + maxTemperature.toString() + ' ℃',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
              Text(
                'Low: ' + minTemperature.toString() + ' ℃',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((value) {
      setState(() {
        _currentPosition = value;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.administrativeArea);
    } catch (e) {
      print(e);
    }
  }
}
