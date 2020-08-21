import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'core/overpass-response.dart';

List<Marker> markers = [];
LatLng savedPosition;
double savedZoom;
MapController mapController;

class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MapController _mapController;
  LatLng currentPosition;

  Future<OverpassResponse> futureOverpassResponse;
  OverpassResponse overpassResponse;

  List<Marker> _markers = <Marker>[];

  List<String> _filters = <String>[];
  final List<FilterEntry> _filterEntries = <FilterEntry>[
    const FilterEntry("Vegan", Icon(Icons.grass), "diet:vegan"),
    const FilterEntry("Vegetarian", Icon(Icons.eco), "diet:vegetarian)"),
    const FilterEntry("Zero waste", Icon(Icons.public), "zero_waste"),
    const FilterEntry("Refills", Icon(Icons.backpack), "bulk_purchase"),
    const FilterEntry("Organic", Icon(Icons.emoji_nature), "organic"),
  ];

  @override
  void initState() {
    _mapController = MapController();
    _getCurrentLocation();
    super.initState();
  }

  Future<OverpassResponse> loadFutureResponse() async {
    const api_url = "https://overpass-api.de/api/interpreter";

    final bounds = _mapController.bounds;

    final queryString = """
[out:json][timeout:25][bbox:${bounds.south},${bounds.west},${bounds.north},${bounds.east}];
(nwr["zero_waste"~"(yes|only|limited)"];
 nwr[~"diet:(vegan|vegetarian)"~"(yes|limited|only)"];
 nwr["organic"~"(yes|limited|only)"];
 nwr["bulk_purchase"~"(yes|limited|only)"];
);
out tags qt center;
""";

    final response = await http.post(api_url,
        body: {"data": queryString}, encoding: Utf8Codec());

    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          json.decode(utf8.decode(response.body.runes.toList())));
    } else {
      throw Exception('Failed to load PoI');
    }
  }

  void loadResponse() {
    futureOverpassResponse = loadFutureResponse();
    futureOverpassResponse.then((_overpassResponse) {
      overpassResponse = _overpassResponse;
      handleResponse();
    }).catchError((error) => print(error));
  }

  Marker createMarker(double lat, double lon, Tags tags) {
    return Marker(
      point: new LatLng(lat, lon),
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => new Container(
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: ctx,
              builder: (BuildContext bc) {
                String addressString = "";
                addressString += tags.addrHousenumber + ", " ?? "?" + ", ";
                addressString += tags.addrStreet + ", " ?? "?" + ", ";
                addressString += tags.addrPostcode ?? "?";

                return Container(
                    child: new Wrap(children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.domain),
                          title: Text(tags.name),
                          subtitle: Text(addressString),
                        ),
                        ListTile(
                          leading: Icon(Icons.airline_seat_flat_angled),
                          title: Text("type of establishment"),
                          subtitle: Text("hello there"),
                        ),
                      ],
                    ),
                  )
                ]));
              },
            );
          },
          child: new Icon(
            Icons.place,
            color: Colors.lightGreen,
            size: 36.0,
          ),
        ),
      ),
    );
  }

//  List filterPoIs(List unfilteredPoIs) {
//    List filteredPoIs = new List();
//
//    RegExp re = new RegExp(_filters.join("|"));
//
//    filteredPoIs = unfilteredPoIs
//        .where((PoI) => re.hasMatch(PoI["tags"].keys.join(" ")))
//        .toList();
//
//    return filteredPoIs;
//  }

  void handleResponse() {
    if (overpassResponse == null){
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Please load data before attempting to filter it"),
      ));
      return;
    }

    List<OsmElement> filteredElements =
        overpassResponse.filterElements(_filters);

    setState(() {
      _markers.clear();
      markers.clear();

      filteredElements.forEach((element) {
        //if (!_markers.contains(PoI)) { // would be better but idc

        _markers.add(createMarker(element.lat, element.lon, element.tags));

        //}
        _markers = List.from(_markers);
        markers = List.from(_markers);
      });
    });
  }

  Iterable<Widget> get filterWidgets sync* {
    for (final FilterEntry _filter in _filterEntries) {
      yield Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: FilterChip(
          avatar: CircleAvatar(child: _filter.icon),
          label: Text(_filter.name),
          selected: _filters.contains(_filter.string),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _filters.add(_filter.string);
              } else {
                _filters.removeWhere((String string) {
                  return string == _filter.string;
                });
              }
              handleResponse();
            });
          },
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position _currentPosition) {
      if (_currentPosition != null) {
        setState(() {
          currentPosition =
              LatLng(_currentPosition.latitude, _currentPosition.longitude);
        });
      }
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    LatLng _currentPosition;

    if (currentPosition != null) {
      _currentPosition =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      _mapController.move(_currentPosition, _mapController.zoom);
    } else {
      _currentPosition = LatLng(0, 0);
    }

    return Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                  child: Stack(children: [
                FlutterMap(
                  mapController:
                      _mapController != null ? _mapController : mapController,
                  options: new MapOptions(
                    center: savedPosition != null
                        ? savedPosition
                        : _currentPosition,
                    onPositionChanged: (mapPosition, boolValue) {
                      savedPosition = mapPosition.center;
                      savedZoom = mapPosition.zoom;
                    },
                    zoom: savedZoom != null ? savedZoom : 13.0,
                    maxZoom: 19,
                    minZoom: 0,
                    plugins: [
                      MarkerClusterPlugin(),
                    ],
                  ),
                  layers: [
                    new TileLayerOptions(
                        // tileProvider: NetworkTileProvider(), // needed to make map load on desktop
                        maxZoom: 19,
                        minZoom: 0,
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c']),
                    new MarkerLayerOptions(markers: <Marker>[
                      Marker(
                        anchorPos: AnchorPos.align(AnchorAlign.center),
                        point: _currentPosition,
                        builder: (ctx) => Container(
                          child: new Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 36.0,
                          ),
                        ),
                      )
                    ]),
                    MarkerClusterLayerOptions(
                      maxClusterRadius: 120,
                      size: Size(40, 40),
                      fitBoundsOptions: FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                      markers: _markers.isNotEmpty ? _markers : markers,
                      polygonOptions: PolygonOptions(
                          borderColor: Colors.lightGreen,
                          color: Colors.black12,
                          borderStrokeWidth: 3),
                      builder: (context, markers) {
                        return FloatingActionButton(
                          child: Text(markers.length.toString(),
                              style: TextStyle(color: Colors.white)),
                          onPressed: null,
                          backgroundColor: Colors.lightGreen,
                          heroTag: null,
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Wrap(
                    spacing: 8.0, // gap between adjacent chips
                    runSpacing: -4.0, // gap between lines
                    children: filterWidgets.toList(),
                  ),
                ),
              ])),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                  onPressed: () {},
                  tooltip: 'Add To Map',
                  child: Icon(Icons.add_business, color: Colors.white),
                  backgroundColor: Colors.lightGreen,
                  heroTag: null),
              FloatingActionButton(
                onPressed: loadResponse,
                tooltip: 'Load Points of Interest',
                child: Icon(Icons.search, color: Colors.white),
                backgroundColor: Colors.lightGreen,
                heroTag: null,
              )
            ],
          ),
        ) //
        );
  }
}

class FilterEntry {
  final String name;
  final Icon icon;
  final String string;

  const FilterEntry(this.name, this.icon, this.string);
}
