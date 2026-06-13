import 'dart:convert';

List<Department> departments = [];

List<Department> departmentFromJson(String str) =>
    List<Department>.from(json.decode(str).map((x) => Department.fromJson(x)));

String departmentToJson(List<Department> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Department {
  int id;
  String name;
  String code;
  Department({required this.id, required this.name, required this.code});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['department_id'],
      name: json['name'] ?? json['department_name'] ?? '',
      code: json['code'] ?? json['department_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "department_id": id,
    "name": name,
    "code": code,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department && runtimeType == other.runtimeType && id == other.id;
}
