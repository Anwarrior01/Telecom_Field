import 'client_info.dart';
import 'operation_photo.dart';

class Operation {
  final String id;
  final ClientInfo clientInfo;
  final List<OperationPhoto> photos;
  final DateTime createdAt;
  final String technicianName;
  final String technicianDomain;

  Operation({
    required this.id,
    required this.clientInfo,
    required this.photos,
    required this.createdAt,
    required this.technicianName,
    required this.technicianDomain,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientInfo': clientInfo.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'technicianName': technicianName,
      'technicianDomain': technicianDomain,
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'],
      clientInfo: ClientInfo.fromJson(json['clientInfo']),
      photos: (json['photos'] as List)
          .map((photo) => OperationPhoto.fromJson(photo))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      technicianName: json['technicianName'],
      technicianDomain: json['technicianDomain'],
    );
  }
}