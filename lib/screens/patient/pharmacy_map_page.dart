// import 'package:abc_app/models/pharmacy_model.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class PharmacyMapPage extends StatefulWidget {
//   final PharmacyModel pharmacy;
//
//   const PharmacyMapPage({
//     super.key,
//     required this.pharmacy,
//   });
//
//   @override
//   State<PharmacyMapPage> createState() => _PharmacyMapPageState();
// }
//
// class _PharmacyMapPageState extends State<PharmacyMapPage> {
//   GoogleMapController? _mapController;
//   LatLng? _currentLocation;
//   Set<Marker> _markers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     _setupMarkers();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     final status = await Permission.location.request();
//     if (status.isGranted) {
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//         setState(() {
//           _currentLocation = LatLng(position.latitude, position.longitude);
//         });
//         _updateCamera();
//       } catch (e) {
//         print('Error getting location: $e');
//         // If we can't get current location, use pharmacy location
//         setState(() {
//           _currentLocation = LatLng(widget.pharmacy.latitude, widget.pharmacy.longitude);
//         });
//         _updateCamera();
//       }
//     } else {
//       // If permission denied, use pharmacy location
//       setState(() {
//         _currentLocation = LatLng(widget.pharmacy.latitude, widget.pharmacy.longitude);
//       });
//       _updateCamera();
//     }
//   }
//
//   void _setupMarkers() {
//     final pharmacyMarker = Marker(
//       markerId: const MarkerId('pharmacy'),
//       position: LatLng(widget.pharmacy.latitude, widget.pharmacy.longitude),
//       infoWindow: InfoWindow(
//         title: widget.pharmacy.name,
//         snippet: widget.pharmacy.address,
//       ),
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//     );
//
//     _markers.add(pharmacyMarker);
//
//     // Add current location marker if available
//     if (_currentLocation != null) {
//       final currentLocationMarker = Marker(
//         markerId: const MarkerId('current_location'),
//         position: _currentLocation!,
//         infoWindow: const InfoWindow(title: 'Your Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       );
//       _markers.add(currentLocationMarker);
//     }
//   }
//
//   void _updateCamera() {
//     if (_mapController != null && _currentLocation != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentLocation!, 14),
//       );
//     }
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _updateCamera();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.pharmacy.name),
//       ),
//       body: _currentLocation == null
//           ? const Center(child: CircularProgressIndicator())
//           : GoogleMap(
//         onMapCreated: _onMapCreated,
//         initialCameraPosition: CameraPosition(
//           target: LatLng(widget.pharmacy.latitude, widget.pharmacy.longitude),
//           zoom: 14,
//         ),
//         markers: _markers,
//         myLocationEnabled: true,
//         myLocationButtonEnabled: true,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _getCurrentLocation,
//         child: const Icon(Icons.my_location),
//       ),
//     );
//   }
// }