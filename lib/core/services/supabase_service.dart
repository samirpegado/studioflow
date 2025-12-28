import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';
import '../models/client_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Initial Data RPC
  Future<Map<String, dynamic>?> getInitialData() async {
    try {
      final response = await _client.rpc('get_initial_data');
      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error calling get_initial_data: $e');
      return null;
    }
  }

  // Users
  Future<UserModel?> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // Studios
  Future<List<StudioModel>> getStudios({
    String? cidade,
    double? latitude,
    double? longitude,
    double? raioKm,
  }) async {
    var query = _client.from('studios').select();
    
    // TODO: Implementar busca por cidade e proximidade usando a tabela enderecos
    // Por enquanto, retorna todos os estúdios
    
    final response = await query;
    
    List<StudioModel> studios = (response as List)
        .map((json) => StudioModel.fromJson(json as Map<String, dynamic>))
        .toList();
    
    return studios;
  }

  Future<StudioModel?> getStudio(String studioId) async {
    final response = await _client
        .from('studios')
        .select()
        .eq('id', studioId)
        .maybeSingle();
    
    if (response == null) return null;
    return StudioModel.fromJson(response);
  }

  Future<StudioModel?> getStudioByUserId(String userId) async {
    final response = await _client
        .from('studios')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return StudioModel.fromJson(response);
  }

  // Clients
  Future<ClientModel?> getClient(String clientId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('id', clientId)
        .maybeSingle();
    
    if (response == null) return null;
    return ClientModel.fromJson(response);
  }

  Future<ClientModel?> getClientByUserId(String userId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return ClientModel.fromJson(response);
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final response = await _client.from('clients').insert(data).select().single();
    return ClientModel.fromJson(response);
  }

  // Rooms
  Future<List<RoomModel>> getRoomsByStudio(String studioId) async {
    final response = await _client
        .from('rooms')
        .select()
        .eq('studio_id', studioId)
        .eq('ativo', true);
    
    return (response as List)
        .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final response = await _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    
    if (response == null) return null;
    return RoomModel.fromJson(response);
  }

  Future<RoomModel> createRoom(Map<String, dynamic> data) async {
    final response = await _client.from('rooms').insert(data).select().single();
    return RoomModel.fromJson(response);
  }

  Future<RoomModel> updateRoom(String roomId, Map<String, dynamic> data) async {
    final response = await _client
        .from('rooms')
        .update(data)
        .eq('id', roomId)
        .select()
        .single();
    return RoomModel.fromJson(response);
  }

  // Bookings
  Future<List<BookingModel>> getBookings({
    String? clientId,
    String? studioId,
    String? roomId,
    BookingStatus? status,
  }) async {
    var query = _client.from('bookings').select('''
      *,
      room:rooms(*),
      studio:studios(*),
      client:clients(*)
    ''');

    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }
    if (studioId != null) {
      query = query.eq('studio_id', studioId);
    }
    if (roomId != null) {
      query = query.eq('room_id', roomId);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query.order('start_datetime', ascending: false);
    
    return (response as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final response = await _client
        .from('bookings')
        .select('''
      *,
      room:rooms(*),
      studio:studios(*),
      client:clients(*)
    ''')
        .eq('id', bookingId)
        .maybeSingle();
    
    if (response == null) return null;
    return BookingModel.fromJson(response);
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await _client.from('bookings').insert(data).select().single();
    return BookingModel.fromJson(response);
  }

  Future<BookingModel> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('bookings')
        .update(data)
        .eq('id', bookingId)
        .select()
        .single();
    return BookingModel.fromJson(response);
  }

  // Reviews
  Future<List<ReviewModel>> getReviewsByStudio(String studioId) async {
    final response = await _client
        .from('reviews')
        .select('''
      *,
      client:clients(*)
    ''')
        .eq('studio_id', studioId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel?> getReviewByBooking(String bookingId) async {
    final response = await _client
        .from('reviews')
        .select('''
      *,
      client:clients(*)
    ''')
        .eq('booking_id', bookingId)
        .maybeSingle();
    
    if (response == null) return null;
    return ReviewModel.fromJson(response);
  }

  Future<ReviewModel> createReview(Map<String, dynamic> data) async {
    final response = await _client.from('reviews').insert(data).select().single();
    return ReviewModel.fromJson(response);
  }

}

