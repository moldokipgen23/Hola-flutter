import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'business_detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Business> businesses = [];
  bool loading = true;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final result = await api.get('/businesses', queryParams: {'per_page': '100'});
      final list = (result['businesses']['data'] ?? result['businesses'] ?? []) as List;
      setState(() {
        businesses = list.map((b) => Business.fromJson(b)).toList();
        _buildMarkers();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _buildMarkers() {
    _markers.clear();
    for (final b in businesses) {
      if (b.lat != null && b.lng != null) {
        _markers.add(Marker(
          markerId: MarkerId(b.id.toString()),
          position: LatLng(b.lat!, b.lng!),
          infoWindow: InfoWindow(
            title: b.name,
            snippet: b.category?.name ?? '',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BusinessDetailScreen(slug: b.slug),
              ));
            },
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : businesses.isEmpty
              ? const Center(child: Text('No businesses with locations'))
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(24.8049, 93.9408), // Churachandpur
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                ),
    );
  }
}
