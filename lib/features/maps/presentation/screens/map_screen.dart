import 'dart:math';
import 'dart:async';
import 'package:campign_project/features/sites/provider/site.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/appColors.dart';

class RadiusMapDialog extends StatefulWidget {
  final LatLng initialLocation;

  const RadiusMapDialog({super.key, required this.initialLocation});

  @override
  State<RadiusMapDialog> createState() => _RadiusMapDialogState();
}


class _RadiusMapDialogState extends State<RadiusMapDialog> {
  GoogleMapController? _mapController;
  double _radiusKm = 10.0;
  Set<Marker> _markers = {};
  Timer? _debounceTimer;
  bool _isUpdatingRadius = false;

  @override
  void initState() {
    super.initState();
    _updateMarkers(widget.initialLocation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRadius = context.read<SiteProvider>().radiusKm;
      setState(() {
        _radiusKm = currentRadius;
      });
      _updateMapZoomForRadius(currentRadius);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers(LatLng center) {
    if (!mounted) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: center,
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      };
    });
  }

  void _onCameraMove(CameraPosition position) {
    if (_isUpdatingRadius) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final newRadius = _calculateRadiusFromZoom(position.zoom, MediaQuery.of(context).size.width);

      setState(() {
        _radiusKm = newRadius;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: widget.initialLocation, zoom: position.zoom)),
      );
    });
  }

  double _calculateRadiusFromZoom(double zoom, double screenWidthInPixels) {
    try {
      final metersPerPixel = 156543.03392 * cos(widget.initialLocation.latitude * pi / 180) / pow(2, zoom);
      final visibleMeters = metersPerPixel * screenWidthInPixels;
      final radiusKm = visibleMeters / 2000;
      return radiusKm;
    } catch (e) {
      debugPrint('Error calculating radius: $e');
      return _radiusKm;
    }
  }

  void _updateMapZoomForRadius(double radiusKm) {
    if (_mapController == null) return;

    try {
      _isUpdatingRadius = true;
      final screenWidth = MediaQuery.of(context).size.width;
      final metersPerPixel = 156543.03392 * cos(widget.initialLocation.latitude * pi / 180);
      final targetMeters = radiusKm * 2000;
      final zoom = log(metersPerPixel * screenWidth / targetMeters) / ln2;

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: widget.initialLocation, zoom: zoom)),
      );
    } catch (e) {
      debugPrint('Error updating map zoom: $e');
    } finally {
      _isUpdatingRadius = false;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final currentRadius = context.read<SiteProvider>().radiusKm;
    _updateMapZoomForRadius(currentRadius);
  }

  void _applyRadius() {
    try {
      context.read<SiteProvider>().setRadius(_radiusKm);
      Navigator.pop(context, _radiusKm);
    } catch (e) {
      debugPrint('Error applying radius: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update radius. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const figmaWidth = 338.0;
    const figmaHeight = 598.0;
    final maxDialogWidth = screenSize.width * 0.9;
    final dialogWidth = maxDialogWidth;
    final dialogHeight = dialogWidth * (figmaHeight / figmaWidth);
    final maxHeight = screenSize.height * 0.8;
    final finalHeight = dialogHeight > maxHeight ? maxHeight : dialogHeight;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenSize.width - dialogWidth) / 2,
        vertical: (screenSize.height - finalHeight) / 2,
      ),
      child: SizedBox(
        width: dialogWidth,
        height: finalHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'How far are you willing to travel?',
                    style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: widget.initialLocation, zoom: 13),
                    onCameraMove: _onCameraMove,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: _markers,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        _radiusKm >= 1000 ? '1000+ km' : '${_radiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _applyRadius,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.buttonColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}