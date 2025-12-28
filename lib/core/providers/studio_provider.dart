import 'package:flutter/foundation.dart';
import '../models/studio_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../services/supabase_service.dart';

class StudioProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  StudioModel? _studio;
  List<RoomModel> _rooms = [];
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  StudioModel? get studio => _studio;
  List<RoomModel> get rooms => _rooms;
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudio(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _studio = await _supabaseService.getStudioByUserId(userId);
      
      if (_studio != null) {
        await loadRooms();
        await loadBookings();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRooms() async {
    if (_studio == null) return;
    
    try {
      _rooms = await _supabaseService.getRoomsByStudio(_studio!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBookings({BookingStatus? status}) async {
    if (_studio == null) return;
    
    try {
      _bookings = await _supabaseService.getBookings(
        studioId: _studio!.id,
        status: status,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<RoomModel> createRoom({
    required String nomeSala,
    String? descricao,
    required double valorHora,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final room = await _supabaseService.createRoom({
        'studio_id': _studio!.id,
        'nome_sala': nomeSala,
        'descricao': descricao,
        'valor_hora': valorHora,
        'ativo': true,
      });

      _rooms.add(room);
      notifyListeners();
      return room;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    double? valorRecebido,
    PaymentMethod? formaPagamento,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = <String, dynamic>{
        'status': status.value,
      };

      if (status == BookingStatus.completed) {
        if (valorRecebido != null) {
          data['valor_recebido'] = valorRecebido;
        }
        if (formaPagamento != null) {
          data['forma_pagamento'] = formaPagamento.value;
        }
        data['completed_at'] = DateTime.now().toIso8601String();
      } else if (status == BookingStatus.cancelled) {
        data['cancelled_at'] = DateTime.now().toIso8601String();
        data['cancelled_by'] = _studio!.id;
      }

      await _supabaseService.updateBooking(bookingId, data);
      await loadBookings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

