import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/studio_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/utils/responsive.dart';

class BookingsManagementWidget extends StatefulWidget {
  const BookingsManagementWidget({super.key});

  @override
  State<BookingsManagementWidget> createState() => _BookingsManagementWidgetState();
}

class _BookingsManagementWidgetState extends State<BookingsManagementWidget> {
  BookingStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final studioProvider = Provider.of<StudioProvider>(context, listen: false);
    await studioProvider.loadBookings(status: _filterStatus);
  }

  @override
  Widget build(BuildContext context) {
    final studioProvider = Provider.of<StudioProvider>(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(Responsive.getPadding(context)),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<BookingStatus?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Todos')),
                    ButtonSegment(value: BookingStatus.pending, label: Text('Pendentes')),
                    ButtonSegment(value: BookingStatus.approved, label: Text('Aprovados')),
                    ButtonSegment(value: BookingStatus.completed, label: Text('Finalizados')),
                  ],
                  selected: {_filterStatus},
                  onSelectionChanged: (Set<BookingStatus?> newSelection) {
                    setState(() {
                      _filterStatus = newSelection.first;
                      _loadBookings();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: studioProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : studioProvider.bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum agendamento',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getPadding(context),
                      ),
                      itemCount: studioProvider.bookings.length,
                      itemBuilder: (context, index) {
                        final booking = studioProvider.bookings[index];
                        return _BookingCard(booking: booking);
                      },
                    ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    Color statusColor;
    switch (booking.status) {
      case BookingStatus.pending:
        statusColor = Colors.orange;
        break;
      case BookingStatus.approved:
        statusColor = Colors.green;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        break;
      case BookingStatus.completed:
        statusColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.client?.nome ?? 'Cliente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(booking.startDatetime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${timeFormat.format(booking.startDatetime)} - ${timeFormat.format(booking.endDatetime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (booking.room != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.room, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    booking.room!.nomeSala,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${booking.valorTotal?.toStringAsFixed(2) ?? booking.valorCalculado.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (booking.status == BookingStatus.pending)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _handleStatusChange(context, BookingStatus.approved);
                        },
                        child: const Text('Aprovar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _handleStatusChange(context, BookingStatus.cancelled);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                if (booking.status == BookingStatus.approved)
                  ElevatedButton(
                    onPressed: () {
                      _handleComplete(context);
                    },
                    child: const Text('Finalizar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleStatusChange(BuildContext context, BookingStatus status) {
    final studioProvider = Provider.of<StudioProvider>(context, listen: false);
    studioProvider.updateBookingStatus(booking.id, status);
  }

  void _handleComplete(BuildContext context) {
    // TODO: Mostrar dialog para informar valor recebido e forma de pagamento
    final studioProvider = Provider.of<StudioProvider>(context, listen: false);
    studioProvider.updateBookingStatus(
      booking.id,
      BookingStatus.completed,
      valorRecebido: booking.valorTotal ?? booking.valorCalculado,
    );
  }
}

