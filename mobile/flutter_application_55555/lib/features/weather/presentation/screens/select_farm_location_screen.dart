import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectFarmLocationScreen extends StatefulWidget {
  const SelectFarmLocationScreen({super.key});

  @override
  State<SelectFarmLocationScreen> createState() => _SelectFarmLocationScreenState();
}

class _SelectFarmLocationScreenState extends State<SelectFarmLocationScreen> {
  LatLng _center = const LatLng(24.7136, 46.6753); // Riyadh default
  LatLng? _picked;
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر موقع المزرعة'), backgroundColor: const Color(0xFF008236)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 8),
            onMapCreated: (c) => _controller = c,
            onTap: (pos) {
              setState(() => _picked = pos);
            },
            markers: _picked != null ? {Marker(markerId: const MarkerId('picked'), position: _picked!)} : {},
          ),
          Positioned(
            right: 12,
            left: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008236),
                ),
                onPressed:
                    _picked == null ? null : () => Navigator.pop(context, _picked),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('تأكيد الموقع'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
