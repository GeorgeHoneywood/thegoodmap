import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

//import 'core/overpass-response.dart';

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
  LatLng clickedPosition;

  Future<Map> futurePoI;
  List<Marker> _markers = <Marker>[];
  List _unfilteredPoIs = [];

  String title;
  String text = "No Value Entered";

  List<String> _filters = <String>[];
  final List<FilterEntry> _filterEntries = <FilterEntry>[
    const FilterEntry(
        "Eating out", Icon(Icons.restaurant), "diet:(vegan|vegetarian)"),
    const FilterEntry("Zero waste", Icon(Icons.public), "zero_waste"),
    const FilterEntry("Refills", Icon(Icons.backpack), "bulk_purchase"),
    const FilterEntry("Organic", Icon(Icons.emoji_nature), "organic"),
  ];

  //Position _currentPosition;
  var changesetId;
  bool addClicked = false;
  bool addName = false;
  bool nameAdded = false;

  @override
  void initState() {
    _mapController = MapController();
    _getCurrentLocation();
    super.initState();
  }

  Future<Map> fetchPoI() async {
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
      return json.decode(utf8.decode(response.body.runes.toList()));
    } else {
      throw Exception('Failed to load PoI');
    }
  }

  void loadPoI() {
    futurePoI = fetchPoI();
    futurePoI.then((PoIs) {
      _unfilteredPoIs = PoIs["elements"];
      handlePoI();
    }).catchError((error) => handleError(error));
  }

  Marker createMarker(double lat, double lon, Map<String, dynamic> tags) {
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
                tags["addr:housenumber"] != null
                    ? addressString += tags["addr:housenumber"] + ", "
                    : addressString += "?" + ", ";
                tags["addr:street"] != null
                    ? addressString += tags["addr:street"] + ", "
                    : addressString += "?" + ", ";
                tags["addr:postcode"] != null
                    ? addressString += tags["addr:postcode"]
                    : addressString += "?";

                return Container(
                    child: new Wrap(children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.domain),
                          title: Text(tags["name"]),
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

  List filterPoIs(List unfilteredPoIs) {
    List filteredPoIs = new List();

//    PoIs.forEach((PoI) {
//      if (PoI["tags"].containsKey("diet:vegan")) {
//        filteredPoIs.add(PoI);
//      }
//    });

    RegExp re = new RegExp(_filters.join("|"));

    filteredPoIs = unfilteredPoIs
        .where((PoI) => re.hasMatch(PoI["tags"].keys.join(" ")))
        .toList();

    return filteredPoIs;
  }

  void handlePoI() {
    List filteredPoIs = filterPoIs(_unfilteredPoIs);

    setState(() {
      _markers.clear();
      markers.clear();

      filteredPoIs.forEach((PoI) {
        //if (!_markers.contains(PoI)) { // would be better but idc

        if (PoI["type"] == "node") {
          _markers.add(createMarker(PoI["lat"], PoI["lon"], PoI["tags"]));
        } else {
          _markers.add(createMarker(
              PoI["center"]["lat"], PoI["center"]["lon"], PoI["tags"]));
        }
        //}
        _markers = List.from(_markers);
        markers = List.from(_markers);
      });
    });
  }

  void handleError(error) {
    print(error);
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
              handlePoI();
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

  Future<String> _uploadNode(LatLng latlng) async {
    final response = await http.put(
        "https://master.apis.dev.openstreetmap.org/api/0.6/node/create",
        headers: {
          "authorization": 'Basic ' +
              base64Encode(utf8.encode("thegoodmap:TCbg93UZ9zeAiM6")),
          "content-type": "text/xml",
        },
        body: """
<osm>
 <node changeset="$changesetId" lat="${latlng.latitude}" lon="${latlng.longitude}">
   <tag k="amenity" v="restaurant"/>
   <tag k="name" v="$title"/>
   <tag k="diet:vegan" v="yes"/>
   <tag k="diet:vegetarian" v="yes"/>
   <tag k="zero_waste" v="no"/>
   <tag k="bulk_purchase" v="no"/>
   <tag k="organic" v="no"/>
   <tag k="second_hand" v="no"/>_
 </node>
</osm>
    """);
    return response.body;
  }

  _handletap(LatLng _clickedPosition) {
    if (addClicked == false) {
      return;
    }

    clickedPosition = _clickedPosition;
    setState(() {
      addName = true;
    });
  }

  _uploadPlace() {
    var futureUploadNode = _uploadNode(clickedPosition);
    futureUploadNode.then((value) {
      print(value);
    });
    setState(() {
      addName = false;
    });

  }

  Widget _buildChild() {
    if (addName == true) {
      return TextField(
        decoration: InputDecoration(
            hintText: 'Name of business', icon: Icon(Icons.edit)),
        onChanged: (value) => title = value,
        onSubmitted: (value) {
          _uploadPlace();
        },
      );
    }
    return null;
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
              Padding(
                padding: const EdgeInsets.all(15),
                child: Container(child: _buildChild()),
              ),
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
                    onTap: _handletap,
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
                  onPressed: () {
                    Future<String> openChangeset() async {
                      final response = await http.put(
                          "https://master.apis.dev.openstreetmap.org/api/0.6/changeset/create",
                          headers: {
                            "authorization": 'Basic ' +
                                base64Encode(
                                    utf8.encode("thegoodmap:TCbg93UZ9zeAiM6")),
                            "content-type": "text/xml",
                          },
                          body: """
<osm>
    <changeset>
    <tag k="created_by" v="The Good Map"/>
    <tag k="comment" v="Testing"/>
    </changeset>
</osm>
""");
                      return response.body;
                    }

                    var futureOpenChangeset = openChangeset();

                    futureOpenChangeset.then((value) {
                      print(value);
                      changesetId = value;
                    });

                    addClicked = true;
                  },
                  tooltip: 'Add To Map',
                  child: Icon(Icons.add_business, color: Colors.white),
                  backgroundColor: Colors.lightGreen,
                  heroTag: null),
              FloatingActionButton(
                onPressed: loadPoI,
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
