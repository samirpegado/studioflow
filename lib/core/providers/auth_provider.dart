import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';
import '../services/supabase_service.dart';

enum UserType { client, studio, unknown }

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  UserModel? _user;
  StudioModel? _studio;
  UserType _userType = UserType.unknown;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  StudioModel? get studio => _studio;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isAuthenticated => _userType != UserType.unknown && (_user != null || _studio != null);
  bool get isStudio => _userType == UserType.studio && _studio != null;
  bool get isClient => _userType == UserType.client && _user != null;

  Future<void> initialize() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      await loadInitialData();
    }
    
    _supabaseService.authStateChanges.listen((state) async {
      if (state.session?.user != null) {
        await loadInitialData();
      } else {
        _user = null;
        _studio = null;
        _userType = UserType.unknown;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.signIn(email, password);
      
      if (response.user != null) {
        return true;
      }
      
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _supabaseService.getInitialData();
      
      if (result == null) {
        _error = 'Erro ao carregar dados iniciais';
        _userType = UserType.unknown;
        notifyListeners();
        return;
      }

      if (result['error'] != null) {
        _error = result['error'] as String;
        _userType = UserType.unknown;
        notifyListeners();
        return;
      }

      final type = result['type'] as String;
      final data = result['data'] as Map<String, dynamic>;

      if (type == 'client') {
        _user = UserModel.fromJson(data);
        _studio = null;
        _userType = UserType.client;
      } else if (type == 'studio') {
        _studio = StudioModel.fromJson(data);
        _user = null;
        _userType = UserType.studio;
      } else {
        _error = 'Tipo de usuário desconhecido';
        _userType = UserType.unknown;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _userType = UserType.unknown;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    _studio = null;
    _userType = UserType.unknown;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
