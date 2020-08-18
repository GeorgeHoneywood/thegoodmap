import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;

class PageOne extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //title: 'The Good Map',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _counter = 0;

  Future<Map> futurePoI;

  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  Future<Map> fetchPoI() async {
    const api_url = "https://overpass-api.de/api/interpreter";

    final bounds = mapController.bounds;

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
              context,
              MaterialPageRoute(
                builder: (context) => DetailTable(tags: tags),
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
    });
  }

  void handleError(error) {
    print("pain");
  }

  List<Marker> _markers = <Marker>[];

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
                mapController: mapController,
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
                    markers: _markers,
                    polygonOptions: PolygonOptions(
                        borderColor: Colors.lightGreen,
                        color: Colors.black12,
                        borderStrokeWidth: 3),
                    builder: (context, markers) {
                      return FloatingActionButton(
                        child: Text(markers.length.toString()),
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
      floatingActionButton: FloatingActionButton(
        onPressed: loadPoI,
        tooltip: 'Load Points of Interest',
        child: Icon(Icons.search),
        backgroundColor: Colors.lightGreen,
        // alignment: Alignment.bottomRight,
      ),
      //floatingActionButton1: FloatingActionButton(
      //onPressed: () {
      //
      // },
      //tooltip: 'Add to map',
      //child: Icon(Icons.add),
      //onPressed: null,
      //tooltip: 'Add to map',
      //child: Icon(Icons.add),
      //backgroundColor: Colors.lightGreen,
      //alignment: Alignment.bottomLeft
      //)// This trailing comma makes auto-formatting nicer for build methods.
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
