import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../models/studio_model.dart';
import '../models/booking_model.dart';
import '../services/supabase_service.dart';

class ClientProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  ClientModel? _client;
  List<StudioModel> _studios = [];
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  ClientModel? get client => _client;
  List<StudioModel> get studios => _studios;
  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClient(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _client = await _supabaseService.getClientByUserId(userId);
      
      if (_client != null) {
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

  Future<void> searchStudios({
    String? cidade,
    double? latitude,
    double? longitude,
    double? raioKm,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _studios = await _supabaseService.getStudios(
        cidade: cidade,
        latitude: latitude,
        longitude: longitude,
        raioKm: raioKm,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings() async {
    if (_client == null) return;
    
    try {
      _bookings = await _supabaseService.getBookings(
        clientId: _client!.id,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<BookingModel> createBooking({
    required String roomId,
    required String studioId,
    required DateTime startDatetime,
    required DateTime endDatetime,
    required double valorHora,
    String? observacoes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final valorTotal = _calculateTotal(startDatetime, endDatetime, valorHora);

      final booking = await _supabaseService.createBooking({
        'client_id': _client!.id,
        'room_id': roomId,
        'studio_id': studioId,
        'start_datetime': startDatetime.toIso8601String(),
        'end_datetime': endDatetime.toIso8601String(),
        'valor_hora': valorHora,
        'valor_total': valorTotal,
        'status': 'pending',
        'observacoes': observacoes,
      });

      await loadBookings();
      return booking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId, String motivo) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabaseService.updateBooking(bookingId, {
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancelled_by': _client!.userId,
        'motivo_cancelamento': motivo,
      });

      await loadBookings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _calculateTotal(DateTime start, DateTime end, double valorHora) {
    final duration = end.difference(start);
    final horas = duration.inMinutes / 60.0;
    return valorHora * horas;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

