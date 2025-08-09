class ClientInfo {
  final String sip;
  final String workOrder;
  final String contactName;
  final String phoneNumber;
  final String id;

  ClientInfo({
    required this.sip,
    required this.workOrder,
    required this.contactName,
    required this.phoneNumber,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'sip': sip,
      'workOrder': workOrder,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'id': id,
    };
  }

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      sip: json['sip'] ?? '',
      workOrder: json['workOrder'] ?? '',
      contactName: json['contactName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      id: json['id'] ?? '',
    );
  }
}
