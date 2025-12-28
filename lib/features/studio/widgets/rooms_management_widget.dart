import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/studio_provider.dart';
import '../../../core/models/room_model.dart';
import '../../../core/utils/responsive.dart';
import 'room_form_dialog.dart';

class RoomsManagementWidget extends StatelessWidget {
  const RoomsManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final studioProvider = Provider.of<StudioProvider>(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(Responsive.getPadding(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Salas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const RoomFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Sala'),
              ),
            ],
          ),
        ),
        Expanded(
          child: studioProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : studioProvider.rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.room_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma sala cadastrada',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione sua primeira sala',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getPadding(context),
                      ),
                      itemCount: studioProvider.rooms.length,
                      itemBuilder: (context, index) {
                        final room = studioProvider.rooms[index];
                        return _RoomCard(room: room);
                      },
                    ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          room.nomeSala,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: room.descricao != null ? Text(room.descricao!) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ ${room.valorHora.toStringAsFixed(2)}/h',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (!room.ativo)
              Text(
                'Inativa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
          ],
        ),
        isThreeLine: room.descricao != null,
      ),
    );
  }
}

