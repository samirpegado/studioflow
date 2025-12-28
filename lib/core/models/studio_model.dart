class StudioModel {
  final String id;
  final String? nome;
  final String? email;
  final String? telefone;
  final String? imgUrl;
  final String? customerId;
  final DateTime? dataAssinatura;
  final String? statusAssinatura;
  final String? cpfCnpj;
  final String? nomeLegal;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  StudioModel({
    required this.id,
    this.nome,
    this.email,
    this.telefone,
    this.imgUrl,
    this.customerId,
    this.dataAssinatura,
    this.statusAssinatura,
    this.cpfCnpj,
    this.nomeLegal,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudioModel.fromJson(Map<String, dynamic> json) {
    return StudioModel(
      id: json['id'] as String,
      nome: json['nome'] as String?,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      imgUrl: json['img_url'] as String?,
      customerId: json['customer_id'] as String?,
      dataAssinatura: json['data_assinatura'] != null 
          ? DateTime.parse(json['data_assinatura'] as String) 
          : null,
      statusAssinatura: json['status_assinatura'] as String?,
      cpfCnpj: json['cpf_cnpj'] as String?,
      nomeLegal: json['nome_legal'] as String?,
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
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'img_url': imgUrl,
      'customer_id': customerId,
      'data_assinatura': dataAssinatura?.toIso8601String().split('T')[0],
      'status_assinatura': statusAssinatura,
      'cpf_cnpj': cpfCnpj,
      'nome_legal': nomeLegal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
