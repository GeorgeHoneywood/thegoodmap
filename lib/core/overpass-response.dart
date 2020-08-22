class OverpassResponse {
  double version;
  String generator;
  List<OsmElement> elements;
  List<OsmElement> filteredElements = [];

  OverpassResponse({this.version, this.generator, this.elements});

  OverpassResponse.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    generator = json['generator'];
    if (json['elements'] != null) {
      elements = new List<OsmElement>();
      json['elements'].forEach((v) {
        elements.add(new OsmElement.fromJson(v));
      });
    }
  }

  List<OsmElement> filterElements(List filterList) {
    if (filterList.isEmpty){
      return elements;
    }

    elements.forEach((element) {
      filterList.forEach((filter) {
        if (filter == "diet:vegan") {
          if (element.tags.dietVegan != null) {
            filteredElements.add(element);
          }
        } else if (filter == "diet:vegetarian") {
          if (element.tags.dietVegetarian != null) {
            filteredElements.add(element);
          }
        } else if (filter == "zero_waste") {
          if (element.tags.zeroWaste != null) {
            filteredElements.add(element);
          }
        } else if (filter == "bulk_purchase") {
          if (element.tags.bulkPurchase != null) {
            filteredElements.add(element);
          }
        } else if (filter == "organic") {
          if (element.tags.organic != null) {
            filteredElements.add(element);
          }
        }
      });
    });

    return filteredElements;
  }
}

class OsmElement {
  String type;
  int id;
  double lat;
  double lon;
  Tags tags;
  Details details;

  OsmElement({this.type, this.id, this.lat, this.lon, this.tags});

  OsmElement.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    id = json['id'];

    if (type == "node") {
      lat = json['lat'];
      lon = json['lon'];
    } else {
      lat = json['center']["lat"];
      lon = json['center']["lon"];
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
      this.organic,
      this.takeaway,
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

class Details {
  String completeAddress;
}
