import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/studio_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/utils/responsive.dart';

class StudioDashboardWidget extends StatelessWidget {
  const StudioDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final studioProvider = Provider.of<StudioProvider>(context);

    if (studioProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studioProvider.studio == null) {
      return const Center(
        child: Text('Carregando informações do estúdio...'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo, ${studioProvider.studio!.nomeEstudio}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    studioProvider.studio!.enderecoCompleto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Resumo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.room,
                  label: 'Salas',
                  value: studioProvider.rooms.length.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Agendamentos',
                  value: studioProvider.bookings.length.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.pending,
                  label: 'Pendentes',
                  value: studioProvider.bookings
                      .where((b) => b.status == BookingStatus.pending)
                      .length
                      .toString(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Finalizados',
                  value: studioProvider.bookings
                      .where((b) => b.status == BookingStatus.completed)
                      .length
                      .toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

