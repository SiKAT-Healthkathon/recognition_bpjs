import 'package:equatable/equatable.dart';

enum DetectionStatus { noFace, fail, success }

class ResponseModel extends Equatable {
  final DetectionStatus status;
  final String message;
  final String? data;

  const ResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponseModel(
      status: json['status'] == 0
          ? DetectionStatus.noFace
          : json['status'] == 1
              ? DetectionStatus.fail
              : DetectionStatus.success,
      message: json['message'],
      data: json['data'],
    );
  }

  // Method untuk mengkonversi instance ke format JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [status, message, data];
}
