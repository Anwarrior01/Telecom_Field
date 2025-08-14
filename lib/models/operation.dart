import 'client_info.dart';
import 'operation_photo.dart';

class Operation {
  final String id;
  final ClientInfo clientInfo;
  final List<OperationPhoto> photos;
  final DateTime createdAt;
  final String technicianName;
  final String technicianNumber; // Changed from technicianDomain to technicianNumber

  Operation({
    required this.id,
    required this.clientInfo,
    required this.photos,
    required this.createdAt,
    required this.technicianName,
    required this.technicianNumber, // Updated parameter
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientInfo': clientInfo.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'technicianName': technicianName,
      'technicianNumber': technicianNumber, // Updated field name
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
      technicianNumber: json['technicianNumber'] ?? json['technicianDomain'] ?? '', // Backward compatibility
    );
  }
}