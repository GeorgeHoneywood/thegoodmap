import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;

List<Marker> markers = [];
MapController mapController;

class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MapController _mapController;

  Future<Map> futurePoI;
  List<Marker> _markers = <Marker>[];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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

    final response = await http.post(api_url, body: {"data": queryString});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load PoI');
    }
  }

  void loadPoI() {
    futurePoI = fetchPoI();
    futurePoI
        .then((value) => handlePoI(value))
        .catchError((error) => handleError(error));
  }

  Marker createMarker(double lat, double lon, Map<String, dynamic> tags) {
    return Marker(
      point: new LatLng(lat, lon),
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (ctx) => new Container(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (ctx) => DetailTable(tags: tags),
              ),
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

  void handlePoI(PoIs) {
    PoIs = PoIs["elements"];

    setState(() {
      PoIs.forEach((PoI) {
        if (PoI["type"] == "node") {
          _markers.add(createMarker(PoI["lat"], PoI["lon"], PoI["tags"]));
        } else {
          _markers.add(createMarker(
              PoI["center"]["lat"], PoI["center"]["lon"], PoI["tags"]));
        }
      });
      _markers = List.from(_markers);
      markers = _markers;
    });
  }

  void handleError(error) {
    print(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: FlutterMap(
                mapController: _mapController != null ? _mapController : mapController,
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 13.0,
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
                  // new MarkerLayerOptions(markers: _markers), // before i used the cluster thingy
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
                        child: Text(markers.length.toString(), style: TextStyle( color: Colors.white)),
                        onPressed: null,
                        backgroundColor: Colors.lightGreen,
                        heroTag: null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
                onPressed: () {},
                tooltip: 'Add To Map',
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.lightGreen,
                heroTag: null
            ),
            FloatingActionButton(
              onPressed: loadPoI,
              tooltip: 'Load Points of Interest',
              child: Icon(Icons.search, color: Colors.white),
              backgroundColor: Colors.lightGreen,
              heroTag: null,
            )
          ],
        ),
      )//


    );
  }
}

class DetailTable extends StatelessWidget {
  final Map tags;

  DetailTable({Key key, @required this.tags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DataRow> _dataRows = [];

    tags.forEach((key, value) {
      _dataRows.add(new DataRow(cells: <DataCell>[
        new DataCell(Text(key)),
        new DataCell(Text(value)),
      ]));
    });

    return Scaffold(
        appBar: AppBar(
          title: Text(tags["name"]),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(0),
            child: Container(
              child: Column(
                children: [
                  DataTable(
                    dataRowHeight: 35,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Key',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Value',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    rows: _dataRows,
                  ),
                ],
              ),
            )));
  }
}
