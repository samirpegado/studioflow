import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/studio_model.dart';
import '../models/client_model.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  UserModel? _user;
  StudioModel? _studio;
  ClientModel? _client;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  StudioModel? get studio => _studio;
  ClientModel? get client => _client;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isStudio => _user?.role == UserRole.studio;
  bool get isClient => _user?.role == UserRole.client;
  bool get isAdmin => _user?.role == UserRole.admin;

  Future<void> initialize() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      await loadUser(currentUser.id);
    }
    
    _supabaseService.authStateChanges.listen((state) async {
      if (state.session?.user != null) {
        await loadUser(state.session!.user.id);
      } else {
        _user = null;
        _studio = null;
        _client = null;
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
        await loadUser(response.user!.id);
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

  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.signUp(email, password);
      
      if (response.user != null) {
        await loadUser(response.user!.id);
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

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    _studio = null;
    _client = null;
    notifyListeners();
  }

  Future<void> loadUser(String userId) async {
    try {
      _user = await _supabaseService.getUser(userId);
      
      if (_user != null) {
        if (_user!.role == UserRole.studio) {
          _studio = await _supabaseService.getStudioByUserId(userId);
        } else if (_user!.role == UserRole.client) {
          _client = await _supabaseService.getClientByUserId(userId);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

