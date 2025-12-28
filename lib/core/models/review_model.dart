import 'client_model.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String clientId;
  final String studioId;
  final int rating;
  final String? comentario;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Relacionamentos
  final ClientModel? client;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.studioId,
    required this.rating,
    this.comentario,
    required this.createdAt,
    this.updatedAt,
    this.client,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      clientId: json['client_id'] as String,
      studioId: json['studio_id'] as String,
      rating: json['rating'] as int,
      comentario: json['comentario'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      client: json['client'] != null 
          ? ClientModel.fromJson(json['client'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'client_id': clientId,
      'studio_id': studioId,
      'rating': rating,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
