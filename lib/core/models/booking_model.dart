import 'room_model.dart';
import 'studio_model.dart';
import 'client_model.dart';

enum BookingStatus { pending, approved, cancelled, completed }

extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.approved:
        return 'approved';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
    }
  }
  
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pendente';
      case BookingStatus.approved:
        return 'Aprovado';
      case BookingStatus.cancelled:
        return 'Cancelado';
      case BookingStatus.completed:
        return 'Finalizado';
    }
  }
  
  static BookingStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;
      case 'approved':
        return BookingStatus.approved;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}

enum PaymentMethod { dinheiro, pix, cartaoDebito, cartaoCredito, transferencia }

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.dinheiro:
        return 'dinheiro';
      case PaymentMethod.pix:
        return 'pix';
      case PaymentMethod.cartaoDebito:
        return 'cartao_debito';
      case PaymentMethod.cartaoCredito:
        return 'cartao_credito';
      case PaymentMethod.transferencia:
        return 'transferencia';
    }
  }
  
  String get label {
    switch (this) {
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
      case PaymentMethod.pix:
        return 'PIX';
      case PaymentMethod.cartaoDebito:
        return 'Cartão de Débito';
      case PaymentMethod.cartaoCredito:
        return 'Cartão de Crédito';
      case PaymentMethod.transferencia:
        return 'Transferência';
    }
  }
  
  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'dinheiro':
        return PaymentMethod.dinheiro;
      case 'pix':
        return PaymentMethod.pix;
      case 'cartao_debito':
        return PaymentMethod.cartaoDebito;
      case 'cartao_credito':
        return PaymentMethod.cartaoCredito;
      case 'transferencia':
        return PaymentMethod.transferencia;
      default:
        return null;
    }
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String roomId;
  final String studioId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final BookingStatus status;
  final double valorHora;
  final double? valorTotal;
  final double? valorRecebido;
  final PaymentMethod? formaPagamento;
  final String? observacoes;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? motivoCancelamento;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Relacionamentos
  final RoomModel? room;
  final StudioModel? studio;
  final ClientModel? client;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.roomId,
    required this.studioId,
    required this.startDatetime,
    required this.endDatetime,
    required this.status,
    required this.valorHora,
    this.valorTotal,
    this.valorRecebido,
    this.formaPagamento,
    this.observacoes,
    this.cancelledAt,
    this.cancelledBy,
    this.motivoCancelamento,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
    this.room,
    this.studio,
    this.client,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      roomId: json['room_id'] as String,
      studioId: json['studio_id'] as String,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      status: BookingStatusExtension.fromString(json['status'] as String),
      valorHora: (json['valor_hora'] as num).toDouble(),
      valorTotal: json['valor_total'] != null 
          ? (json['valor_total'] as num).toDouble() 
          : null,
      valorRecebido: json['valor_recebido'] != null 
          ? (json['valor_recebido'] as num).toDouble() 
          : null,
      formaPagamento: PaymentMethodExtension.fromString(json['forma_pagamento'] as String?),
      observacoes: json['observacoes'] as String?,
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at'] as String) 
          : null,
      cancelledBy: json['cancelled_by'] as String?,
      motivoCancelamento: json['motivo_cancelamento'] as String?,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      room: json['room'] != null 
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>) 
          : null,
      studio: json['studio'] != null 
          ? StudioModel.fromJson(json['studio'] as Map<String, dynamic>) 
          : null,
      client: json['client'] != null 
          ? ClientModel.fromJson(json['client'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'room_id': roomId,
      'studio_id': studioId,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'status': status.value,
      'valor_hora': valorHora,
      'valor_total': valorTotal,
      'valor_recebido': valorRecebido,
      'forma_pagamento': formaPagamento?.value,
      'observacoes': observacoes,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancelled_by': cancelledBy,
      'motivo_cancelamento': motivoCancelamento,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  Duration get duracao {
    return endDatetime.difference(startDatetime);
  }
  
  double get valorCalculado {
    final horas = duracao.inMinutes / 60.0;
    return valorHora * horas;
  }
  
  bool get podeCancelar {
    if (status == BookingStatus.cancelled || status == BookingStatus.completed) {
      return false;
    }
    final agora = DateTime.now();
    final diferenca = startDatetime.difference(agora);
    return diferenca.inHours >= 24;
  }
}

