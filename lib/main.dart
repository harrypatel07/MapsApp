import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong/latlong.dart' as dis;
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: MyHomePage(title: 'Maps App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController _controller;

  static LatLng _center = const LatLng(29.9844, 31.2297);

  CameraPosition position = new CameraPosition(target: _center, zoom: 17);

  final Set<Marker> _markers = {};

  var location = new Location();

  BitmapDescriptor myIcon;

  CameraPosition currentPosition =
          new CameraPosition(target: _center, zoom: 17),
      prevPosition = new CameraPosition(target: _center, zoom: 17);

  double bearing;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  _getLocation() async {
    location.onLocationChanged().listen((LocationData currentLocation) {
      setState(() {
        print('location');
        print(currentLocation.latitude);
        print(currentLocation.longitude);
//        _center = LatLng(currentLocation.latitude, currentLocation.longitude);

        position = new CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 17);

        move(position);
      });
    });
  }

  Future<void> move(CameraPosition position) async {
//    bearing = getBearingBetweenTwoPoints1(prevPosition.target, position.target);
    if (prevPosition != position) {
      prevPosition = currentPosition;
      currentPosition = position;
      await distance(prevPosition.target, position.target);
//    _controller.animateCamera(CameraUpdate.newCameraPosition(position));
//    setState(() {
//      _markers.clear();
//      _markers.add(Marker(
//          markerId: MarkerId(position.target.toString()),
//          position: position.target,
//          icon: myIcon,
//          rotation: bearing,
//          draggable: true,
//          anchor: Offset(0.5, 0.5)));
//    });
    }
  }

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(128, 128)), 'assets/images/car.png')
        .then((onValue) {
      print('onValue.toString()');
      setState(() {
        myIcon = onValue;
      });
    });

    _getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: position,
            markers: _markers,
            myLocationEnabled: true,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: () => move(position),
                backgroundColor: Colors.grey,
                child: const Icon(Icons.map, size: 36.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  distance(LatLng prev, LatLng next) async {
    dis.Distance distance = new dis.Distance();
    double meter = distance(new dis.LatLng(prev.latitude, prev.longitude),
        new dis.LatLng(next.latitude, next.longitude));
    print('dis $meter');
    if (meter != 0) await points(prev, next, meter);
  }

  points(LatLng prev, LatLng next, double dis) async {
    int count = (dis).round();
    print('count $count');
    double d = sqrt(
            (prev.latitude - next.latitude) * (prev.latitude - next.latitude) +
                (prev.longitude - next.longitude) *
                    (prev.longitude - next.longitude)) /
        count;
    double fi =
        atan2(next.longitude - prev.longitude, next.latitude - prev.latitude);

    List<LatLng> points = new List();

    for (int i = 0; i <= count; ++i)
      points.add(new LatLng(
          prev.latitude + i * d * cos(fi), prev.longitude + i * d * sin(fi)));
//    points.add(next);
    await moveMarker(count, points, prev, next);
  }

  moveMarker(int count, List<LatLng> points, LatLng prev, LatLng next) async {
    print('points ${points.toString()}');
    int counter = 0;
    if (count != 0)
      Timer.periodic(Duration(milliseconds: (1000 / count).round()), (timer) {
        if (counter == count - 1 || count == 0) timer.cancel();
        setState(() {
          bearing = getBearingBetweenTwoPoints1(prev, next);
          _controller.animateCamera(CameraUpdate.newCameraPosition(
              new CameraPosition(target: points[counter], zoom: 17)));
          _markers.clear();
          _markers.add(Marker(
              markerId: MarkerId(position.target.toString()),
              position: points[counter],
              icon: myIcon,
              rotation: bearing,
              draggable: true,
              anchor: Offset(0.5, 0.5)));
        });

        counter++;
      });
  }

  double getBearingBetweenTwoPoints1(LatLng latLng1, LatLng latLng2) {
    double lat1 = degreesToRadians(latLng1.latitude);
    double long1 = degreesToRadians(latLng1.longitude);
    double lat2 = degreesToRadians(latLng2.latitude);
    double long2 = degreesToRadians(latLng2.longitude);

    double dLon = (long2 - long1);

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double radiansBearing = atan2(y, x);

    return radiansToDegrees(radiansBearing);
  }

  double degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double radiansToDegrees(double radians) {
    return radians * 180.0 / pi;
  }
}
