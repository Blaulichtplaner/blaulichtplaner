class Company {
  String id;
  String selfPath;
  String companyName;

  Company.empty();

  Company.fromMap(String selfPath, String id, Map<String, dynamic> mapData) {
    this.id = id;
    this.selfPath = selfPath;
    this.companyName = mapData["companyName"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["companyName"] = companyName;
    return result;
  }
}

class WorkingHours {
  DateTime from;
  DateTime to;

  WorkingHours();

  WorkingHours.fromTo(DateTime from, DateTime to) {
    this.from = DateTime(1970, 1, 1, from.hour, from.minute);
    this.to = DateTime(1970, 1, 1, to.hour, to.minute);
  }

  WorkingHours.fromMap(Map<String, dynamic> mapData) {
    this.from = mapData["from"];
    this.to = mapData["to"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["from"] = from;
    result["to"] = to;
    return result;
  }
}

class CompanyLocation {
  String locationName;

  CompanyLocation.empty();

  CompanyLocation.fromMap(Map<String, dynamic> mapData) {
    this.locationName = mapData["locationName"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["locationName"] = locationName;
    return result;
  }
}

class LocationWorkArea {
  String workAreaName;
  String color;
  
  LocationWorkArea.empty();

  LocationWorkArea.fromMap(Map<String, dynamic> mapData) {
    this.workAreaName = mapData["workAreaName"];
    this.color = mapData["color"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["workAreaName"] = workAreaName;
    result["color"] = color;
    return result;
  }
}

class Invitation {
  String email;
  String employeePath;
  String locationPath;

  Invitation(this.email, this.employeePath, this.locationPath);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result["email"] = email;
    result["employeePath"] = employeePath;
    result["locationPath"] = locationPath;
    return result;
  }
}
