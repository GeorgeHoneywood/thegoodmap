import 'package:flutter/material.dart';

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
    filteredElements.clear();

    if (filterList.isEmpty) {
      return elements;
    }

    elements.forEach((element) {
      filterList.forEach((filter) {
        if (filter == "diet:vegan") {
          if (element.tags.dietVegan != null) {
            filteredElements.add(element);
          }
        } else if (filter == "diet:vegetarian") {
          if (element.tags.dietVegetarian != null ||
              element.tags.dietVegan != null) {
            if (!filteredElements.contains(element)) {
              filteredElements.add(element);
            }
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

    details = Details(this.tags);
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
  String completeAddress = "";
  Tags tags;
  DisplayType displayType;
  BenefitType benefitType;

  Details(Tags tags) {
    this.tags = tags;

    buildAddress();
    buildDisplayType();
    buildBenefitType();
  }

  void buildAddress() {
    completeAddress =
        "${tags.addrHousenumber ?? "?"}, ${tags.addrStreet ?? "?"}, ${tags.addrPostcode ?? "?"}";

    if (completeAddress == "?, ?, ?") {
      completeAddress = "Address unknown";
    }
  }

  void buildDisplayType() {
    String cuisine = tags.cuisine;
    String amenity = tags.amenity;

    if (cuisine == null) {
      cuisine = "Cuisine unknown";
    }

    if (amenity == null) {
      amenity = "Location type unknown";
    }

    cuisine = formatList(splitOnSemi(cuisine));

    if (amenity == "pub") {
      displayType = DisplayType("Pub", cuisine, Icons.local_drink);
    } else if (amenity == "restaurant") {
      displayType = DisplayType("Restaurant", cuisine, Icons.restaurant);
    } else if (amenity == "cafe") {
      displayType = DisplayType("Cafe", cuisine, Icons.local_cafe);
    } else {
      amenity = formatList(splitOnSemi(amenity));

      displayType =
          DisplayType(amenity, cuisine, Icons.place);
    }
  }

  void buildBenefitType(){
    if (tags.dietVegan != null) {
      benefitType = BenefitType("Vegan", "Sells products that are vegan", Icons.grass);
    } else if (tags.dietVegetarian != null) {
      benefitType = BenefitType("Vegetarian", "Sells products that are vegetarian", Icons.eco);
    } else if (tags.zeroWaste != null) {
      benefitType = BenefitType("Zero waste", "Sells eco products", Icons.public);
    } else if (tags.bulkPurchase != null) {
      benefitType = BenefitType("Bulk shop", "Sells products without packaging -- you have to bring your own", Icons.backpack);
    } else if (tags.organic != null) {
      benefitType = BenefitType("Organic", "Sells products that are organic", Icons.emoji_nature);
    }
  }

  List<String> splitOnSemi(String string) {
    return string.split(";");
  }

  String capitaliseFirst(String string) {
    return string[0].toUpperCase() + string.substring(1);
  }

  String formatList(List<String> list) {
    list = list.map((element) {
      return capitaliseFirst(element).replaceAll("_", " ");
    }).toList();

    return list.join(", ");
  }
}

class DisplayType {
  Text title;
  Text cuisine;
  Icon icon;

  DisplayType(title, cuisine, icon) {
    this.title = Text(title);
    this.cuisine = Text(cuisine);
    this.icon = Icon(icon);
  }
}

class BenefitType {
  Text title;
  Text subtitle;
  Icon icon;

  BenefitType(title, cuisine, icon) {
    this.title = Text(title);
    this.subtitle = Text(cuisine);
    this.icon = Icon(icon);
  }
}
