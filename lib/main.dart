import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String loc = "Move the map to select a location";
  final ctrl = MapController();
  final _timer = Limiter(milliseconds: 5);

  // LocationData _currentLocationData;
  // Position _currentPosition;

  void changeLocation(MapPosition p) {
    _timer.run(() {
      debugPrint('location change! ${p.center}');
      _getLocationAddress(p.center!.latitude, p.center!.longitude)
          .then((value) => setState(() {
                loc = value;
              }));
    });
  }

  Widget _buildPopupDialog(BuildContext context, String title, String message) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext context) => _buildPopupDialog(context, 'Alert',
            'Location services are disabled. Please enable the services'),
      );
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showDialog(
          context: context,
          builder: (BuildContext context) => _buildPopupDialog(
              context, 'Alert', 'Location services are denied'),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (BuildContext context) => _buildPopupDialog(context, 'Alert',
            'Location permissions are permanently denied, we cannot request permissions.'),
      );
      return false;
    }
    return true;
  }

  void goToCurrentLocation() {
    _handleLocationPermission().then((hasPermission) {
      if (!hasPermission) return;

      Geolocator.getCurrentPosition().then(
          (value) => ctrl.move(LatLng(value.latitude, value.longitude), 5));
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<String> _getLocationAddress(double latitude, double longitude) async {
    List<Placemark> newPlace =
        await placemarkFromCoordinates(latitude, longitude);
    Placemark placeMark = newPlace[0];
    String? name = placeMark.name;
    String? locality = placeMark.locality;
    String? subLocality = placeMark.subLocality;
    String? administrativeArea = placeMark.administrativeArea;
    // String? subAdministrativeArea = placeMark.subAdministrativeArea;
    // String? postalCode = placeMark.postalCode;
    // String? country = placeMark.country;
    // String? subThoroughfare = placeMark.subThoroughfare;
    // String? thoroughfare = placeMark.thoroughfare;
    // _isoCountryCode = placeMark.isoCountryCode;
    var l = subLocality != null && subLocality.isNotEmpty
        ? '$subLocality \($locality\)'
        : locality;
    return "$l, $administrativeArea";
    // return "$name, $thoroughfare \($subThoroughfare\), $locality, $administrativeArea, $postalCode, $country";
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                loc,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 3 / 4,
            child: FlutterMap(
              mapController: ctrl,
              options: MapOptions(
                  center: LatLng(43.6532, -79.3832),
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    changeLocation(position);
                  }),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.radar.mapper',
                ),
                Center(
                  child: Icon(
                    Icons.location_pin,
                    color: Theme.of(context).colorScheme.primary,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToCurrentLocation,
        tooltip: 'Locate me',
        child: const Icon(Icons.my_location_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Limiter {
  final int milliseconds;
  Timer? _timer;

  Limiter({required this.milliseconds})
      : _timer = Timer(Duration(milliseconds: milliseconds), () => {});

  run(VoidCallback action) {
    if (_timer != null && !_timer!.isActive) {
      _timer = Timer(Duration(milliseconds: milliseconds), action);
    } else {}
  }
}
