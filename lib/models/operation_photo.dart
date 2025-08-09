import 'dart:io';

class OperationPhoto {
  final File imageFile;
  final String description;
  final DateTime timestamp;

  OperationPhoto({
    required this.imageFile,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imageFile.path,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationPhoto.fromJson(Map<String, dynamic> json) {
    return OperationPhoto(
      imageFile: File(json['imagePath']),
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}