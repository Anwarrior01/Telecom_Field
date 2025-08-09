class Technician {
  final String name;
  final String domain;

  Technician({
    required this.name,
    required this.domain,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'domain': domain,
    };
  }

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      name: json['name'],
      domain: json['domain'],
    );
  }
}