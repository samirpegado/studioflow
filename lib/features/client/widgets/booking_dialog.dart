import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/studio_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/providers/client_provider.dart';

class BookingDialog extends StatefulWidget {
  final StudioModel studio;
  final RoomModel room;

  const BookingDialog({
    super.key,
    required this.studio,
    required this.room,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _observacoesController = TextEditingController();

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _createBooking() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    final startDatetime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDatetime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (endDatetime.isBefore(startDatetime) || endDatetime.isAtSameMomentAs(startDatetime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário de término deve ser após o início')),
      );
      return;
    }

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);

    try {
      await clientProvider.createBooking(
        roomId: widget.room.id,
        studioId: widget.studio.id,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        valorHora: widget.room.valorHora,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento solicitado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar agendamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateTotal() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return 0;
    }

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (end.isBefore(start)) return 0;

    final duration = end.difference(start);
    final horas = duration.inMinutes / 60.0;
    return widget.room.valorHora * horas;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agendar - ${widget.room.nomeSala}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'R\$ ${widget.room.valorHora.toStringAsFixed(2)} por hora',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data'),
              subtitle: Text(
                _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : 'Selecione a data',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Horário de Início'),
              subtitle: Text(
                _startTime != null
                    ? _startTime!.format(context)
                    : 'Selecione o horário',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectStartTime,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Horário de Término'),
              subtitle: Text(
                _endTime != null
                    ? _endTime!.format(context)
                    : 'Selecione o horário',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectEndTime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_selectedDate != null && _startTime != null && _endTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R\$ ${_calculateTotal().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _createBooking,
          child: const Text('Agendar'),
        ),
      ],
    );
  }
}

