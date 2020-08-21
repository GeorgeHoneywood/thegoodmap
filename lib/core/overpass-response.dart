class OverpassResponse {
  double version;
  String generator;
  List<Elements> elements;

  OverpassResponse({this.version, this.generator, this.elements});

  OverpassResponse.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    generator = json['generator'];
    if (json['elements'] != null) {
      elements = new List<Elements>();
      json['elements'].forEach((v) {
        elements.add(new Elements.fromJson(v));
      });
    }
  }
}

class Elements {
  String type;
  int id;
  double lat;
  double lon;
  Tags tags;

  Elements({this.type, this.id, this.lat, this.lon, this.tags});

  Elements.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    id = json['id'];

    if (type == "node") {
      lat = json['lat'];
      lon = json['lon'];
    } else {
      lat = json['center']["lat"];
      lat = json['center']["lon"];
    }
    tags = json['tags'] != null ? new Tags.fromJson(json['tags']) : null;
  }
}

class Tags {
  String addrCity;
  String addrHousenumber;
  String addrPostcode;
  String addrStreet;
  String amenity;
  String cuisine;
  String dietGlutenFree;
  String dietVegan;
  String name;
  String openingHours;
  String dietVegetarian;
  String takeaway;
  String organic;
  String zeroWaste;
  String bulkPurchase;

  Tags(
      {this.addrCity,
      this.addrHousenumber,
      this.addrPostcode,
      this.addrStreet,
      this.amenity,
      this.cuisine,
      this.dietGlutenFree,
      this.dietVegan,
      this.name,
      this.openingHours,
      this.dietVegetarian,
      this.takeaway,
        this.organic,
      this.zeroWaste,
      this.bulkPurchase});

  Tags.fromJson(Map<String, dynamic> json) {
    addrCity = json['addr:city'];
    addrHousenumber = json['addr:housenumber'];
    addrPostcode = json['addr:postcode'];
    addrStreet = json['addr:street'];
    amenity = json['amenity'];
    cuisine = json['cuisine'];
    dietGlutenFree = json['diet:gluten_free'];
    dietVegan = json['diet:vegan'];
    name = json['name'];
    openingHours = json['opening_hours'];
    dietVegetarian = json['diet:vegetarian'];
    takeaway = json['takeaway'];
    organic = json['organic'];
    zeroWaste = json['zero_waste'];
    bulkPurchase = json['bulk_purchase'];
  }
}
