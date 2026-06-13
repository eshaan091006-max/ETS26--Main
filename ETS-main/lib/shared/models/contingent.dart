import 'dart:convert';

List<Contingent> contingentFromJson(String str) =>
    List<Contingent>.from(json.decode(str).map((x) => Contingent.fromJson(x)));

String contingentToJson(List<Contingent> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Contingent {
  int contingentId;
  String contingentCode;
  String password;

  Contingent({
    this.contingentId = -1,
    this.contingentCode = "NA",
    this.password = "NA",
  });

  factory Contingent.fromJson(Map<String, dynamic> json) {
    return Contingent(
      contingentId: json['contingent_id'],
      contingentCode: json['contingent_code'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() => {
    "contingent_id": contingentId,
    "contingent_code": contingentCode,
    "password": password,
  };

  Map<String, dynamic> toInsertJson() => {
    "contingent_id": contingentId,
    "contingent_code": contingentCode,
    "password": password,
  };
}
