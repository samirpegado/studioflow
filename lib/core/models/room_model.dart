class RoomModel {
  final String id;
  final String studioId;
  final String nomeSala;
  final String? descricao;
  final double valorHora;
  final bool ativo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  RoomModel({
    required this.id,
    required this.studioId,
    required this.nomeSala,
    this.descricao,
    required this.valorHora,
    required this.ativo,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      studioId: json['studio_id'] as String,
      nomeSala: json['nome_sala'] as String,
      descricao: json['descricao'] as String?,
      valorHora: (json['valor_hora'] as num).toDouble(),
      ativo: json['ativo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studio_id': studioId,
      'nome_sala': nomeSala,
      'descricao': descricao,
      'valor_hora': valorHora,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

