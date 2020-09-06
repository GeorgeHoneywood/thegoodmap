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
Marker userLocationMarker;
Marker addLocationMarker;
LatLng savedMapPosition;
LatLng savedUserPosition;
double savedMapZoom;
MapController mapController;
bool firstBuild = true;

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
  LatLng _currentUserPosition;

  Future<OverpassResponse> futureOverpassResponse;
  OverpassResponse overpassResponse;

  List<Marker> _markers = <Marker>[];
  Marker _userLocationMarker;
  Marker _addLocationMarker;

  String title;

  List<String> _filters = <String>[];
  final List<FilterEntry> _filterEntries = <FilterEntry>[
    const FilterEntry("Vegan", Icon(Icons.grass), "diet:vegan"),
    const FilterEntry("Vegetarian", Icon(Icons.eco), "diet:vegetarian"),
    const FilterEntry("Zero waste", Icon(Icons.public), "zero_waste"),
    const FilterEntry("Refills", Icon(Icons.backpack), "bulk_purchase"),
    const FilterEntry("Organic", Icon(Icons.emoji_nature), "organic"),
    const FilterEntry("Second hand", Icon(Icons.loyalty), "second_hand")
  ];

  //Position _currentPosition;
  var changesetId;
  bool addClicked = false;
  bool addName = false;
  bool nameAdded = false;
  bool editClicked = false;
  bool searchClicked = false;

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
 nwr["second_hand"~"(yes|limited|only)"];
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
    searchClicked = true;
    editClicked = false;
    addClicked = false;
    addName = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          children: <Widget>[
            Center(
              child: CircularProgressIndicator(),
            )
          ],
        );
      },
    );
    futureOverpassResponse = loadFutureResponse();
    futureOverpassResponse.then((_overpassResponse) {
      overpassResponse = _overpassResponse;
      handleResponse();
      Navigator.pop(context);
    }).catchError((error) => print(error));
  }

  Marker createMarker(double lat, double lon, Tags tags, Details details) {
    return Marker(
      point: new LatLng(lat, lon),
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => new Container(
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: ctx,
              builder: (BuildContext bc) {
                return Container(
                    child: new Wrap(children: <Widget>[
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.domain),
                          title: Text(tags.name ?? "?"),
                          subtitle: Text(details.completeAddress),
                        ),
                        ListTile(
                          leading: details.displayType.icon,
                          title: details.displayType.title,
                          subtitle: details.displayType.cuisine,
                        ),
                        ListTile(
                          leading: details.benefitType.icon,
                          title: details.benefitType.title,
                          subtitle: details.benefitType.subtitle,
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

  void handleResponse() {
    if (overpassResponse == null) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Please load data before attempting to filter it"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    if (overpassResponse.elements.isEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("This area has no data, but you can expand your search"),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    List<OsmElement> filteredElements =
        overpassResponse.filterElements(_filters);

    if (filteredElements.isEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("None match this filter"),
        duration: Duration(seconds: 2),
      ));
      setState(() {
        _markers.clear();
        markers.clear();
      });
      return;
    }

    setState(() {
      _markers.clear();
      markers.clear();

      filteredElements.forEach((element) {
        _markers.add(createMarker(
            element.lat, element.lon, element.tags, element.details));
      });
      _markers = List.from(_markers);
      markers = List.from(_markers);
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
                _filters.remove(_filter.string);
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
          _currentUserPosition =
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

  _handleTap(LatLng _clickedPosition) {
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
      //return Padding(
        //padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        return TextField(
          decoration: InputDecoration(
              hintText: 'Name of business', icon: Icon(Icons.edit)),
          onChanged: (value) => title = value,
          onSubmitted: (value) {
            _uploadPlace();
          },
        );
      //);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng _currentPosition;

    if (_currentUserPosition != null) {
      if (firstBuild == true) {
        firstBuild = false;
        _currentPosition = LatLng(
            _currentUserPosition.latitude, _currentUserPosition.longitude);
        _mapController.move(_currentPosition, _mapController.zoom);
      }
    } else {
      _currentPosition = LatLng(0, 0);
    }
    if (addName == true) {
      _addLocationMarker = Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        point: clickedPosition,
        builder: (ctx) => Container(
          child: new Icon(
            Icons.place,
            color: Colors.lightGreen,
            size: 36.0,
          ),),);
      addLocationMarker = _addLocationMarker;
    }
    if (addName == false) { addLocationMarker = null; }

    if (_currentPosition != null) {
      _userLocationMarker = Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        point: _currentPosition, 
        builder: (ctx) => Container(
          child: new Icon(
            Icons.my_location,
            color: Colors.blue,
          ),
        ),
      );
      userLocationMarker = _userLocationMarker;
    }

    return Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(child: _buildChild()),
              Flexible(
                  child: Stack(children: [
                FlutterMap(
                  mapController:
                      _mapController != null ? _mapController : mapController,
                  options: new MapOptions(
                    center: savedMapPosition != null
                        ? savedMapPosition
                        : _currentPosition,
                    zoom: savedMapZoom != null ? savedMapZoom : 13.0,
                    minZoom: 0,
                    maxZoom: 19,
                    onTap: _handleTap,
                    plugins: [
                      MarkerClusterPlugin(),
                    ],
                    onPositionChanged: (mapPosition, boolValue) {
                      savedMapPosition = mapPosition.center;
                      savedMapZoom = mapPosition.zoom;
                    },
                  ),
                  layers: [
                    new TileLayerOptions(
                        // tileProvider: NetworkTileProvider(), // needed to make map load on desktop
                        minZoom: 0,
                        maxZoom: 19,
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c']),
                    new MarkerLayerOptions(markers: <Marker>[
                      userLocationMarker != null
                          ? userLocationMarker
                          : _userLocationMarker,
                      if (addLocationMarker != null) addLocationMarker
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
                    setState(() {
                      editClicked = true;
                      searchClicked = false;
                    });

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
                  backgroundColor: editClicked == false ? Colors.lightGreen : Colors.green,
                  heroTag: null),
              FloatingActionButton(
                onPressed: loadResponse,
                tooltip: 'Load Points of Interest',
                child: Icon(Icons.search, color: Colors.white),
                backgroundColor: searchClicked == false ? Colors.lightGreen: Colors.green,
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
