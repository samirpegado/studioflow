import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/studio_provider.dart';
import '../widgets/studio_dashboard_widget.dart';
import '../widgets/rooms_management_widget.dart';
import '../widgets/bookings_management_widget.dart';

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studioProvider = Provider.of<StudioProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await studioProvider.loadStudio(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<StudioProvider>(
          builder: (context, studioProvider, _) {
            return Text(
              studioProvider.studio?.nomeEstudio ?? 'StudioFlow',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navegar para configurações
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (!mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            StudioDashboardWidget(),
            RoomsManagementWidget(),
            BookingsManagementWidget(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.room),
            label: 'Salas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Agendamentos',
          ),
        ],
      ),
    );
  }
}

