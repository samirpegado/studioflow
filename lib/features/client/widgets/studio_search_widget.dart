import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/client_provider.dart';
import '../../../core/utils/responsive.dart';
import 'studio_card_widget.dart';

class StudioSearchWidget extends StatefulWidget {
  const StudioSearchWidget({super.key});

  @override
  State<StudioSearchWidget> createState() => _StudioSearchWidgetState();
}

class _StudioSearchWidgetState extends State<StudioSearchWidget> {
  final _searchController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Buscar estúdios sem filtro de localização inicialmente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchStudios();
    });
    // Tentar obter localização em background para uso futuro
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _searchStudios();
    } catch (e) {
      // Silenciar erro de localização
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchStudios() async {
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    
    // Só usar filtro de distância se tiver localização E se o usuário quiser filtrar por proximidade
    await clientProvider.searchStudios(
      cidade: _searchController.text.trim().isEmpty 
          ? null 
          : _searchController.text.trim(),
      // Não filtrar por distância por padrão - mostrar todos os estúdios
      latitude: null,
      longitude: null,
      raioKm: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(Responsive.getPadding(context)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por cidade...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _searchStudios(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchStudios,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, _) {
                if (clientProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (clientProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          clientProvider.error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (clientProvider.studios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum estúdio encontrado',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.getPadding(context),
                  ),
                  itemCount: clientProvider.studios.length,
                  itemBuilder: (context, index) {
                    final studio = clientProvider.studios[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: StudioCardWidget(studio: studio),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

