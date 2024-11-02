import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String nik;
  final String name;
  final String photo;
  final DateTime? checkInAt;

  const UserModel({
    required this.nik,
    required this.name,
    required this.photo,
    this.checkInAt,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nik: json['nik'],
      name: json['name'],
      photo: json['photo'],
      checkInAt: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'])
          : null,
    );
  }

  // Method untuk mengkonversi instance ke format JSON
  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'name': name,
      'photo': photo,
      'check_in_at': checkInAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [nik, name, photo, checkInAt];
}
