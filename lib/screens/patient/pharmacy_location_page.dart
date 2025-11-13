// // screens/patient/pharmacy_location_page.dart
// import 'package:abc_app/models/pharmacy_model.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:math';
//
// class PharmacyLocationPage extends StatefulWidget {
//   final List<PharmacyModel> nearbyPharmacies;
//   final Function(LatLng)? onLocationSelected;
//   final bool isSelectingLocation;
//
//   const PharmacyLocationPage({
//     super.key,
//     required this.nearbyPharmacies,
//     this.onLocationSelected,
//     this.isSelectingLocation = false,
//   });
//   @override
//   State<PharmacyLocationPage> createState() => _PharmacyLocationPageState();
// }
//
// class _PharmacyLocationPageState extends State<PharmacyLocationPage> {
//   GoogleMapController? _mapController;
//   LatLng? _currentLocation;
//   LatLng? _selectedLocation;
//   Set<Marker> _markers = {};
//   final double _searchRadius = 10.0; // 10km radius
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       final status = await Permission.location.request();
//       if (status.isGranted) {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//         setState(() {
//           _currentLocation = LatLng(position.latitude, position.longitude);
//           if (widget.isSelectingLocation) {
//             _selectedLocation = _currentLocation;
//           }
//         });
//         _updateCamera();
//         _setupMarkers();
//       }
//     } catch (e) {
//       print('Error getting location: $e');
//       // If we can't get current location, use first pharmacy location
//       if (widget.nearbyPharmacies.isNotEmpty) {
//         setState(() {
//           _currentLocation = LatLng(
//             widget.nearbyPharmacies.first.latitude,
//             widget.nearbyPharmacies.first.longitude,
//           );
//         });
//         _updateCamera();
//         _setupMarkers();
//       }
//     }
//   }
//
//   void _setupMarkers() {
//     _markers.clear();
//
//     // Add current location marker
//     if (_currentLocation != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLocation!,
//           infoWindow: const InfoWindow(title: 'Your Location'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         ),
//       );
//     }
//
//     // Add pharmacy markers
//     for (var pharmacy in widget.nearbyPharmacies) {
//       // Calculate distance for this pharmacy
//       double distance = 0.0;
//       if (_currentLocation != null) {
//         distance = _calculateDistance(
//           _currentLocation!.latitude,
//           _currentLocation!.longitude,
//           pharmacy.latitude,
//           pharmacy.longitude,
//         );
//       }
//
//       _markers.add(
//         Marker(
//           markerId: MarkerId(pharmacy.id ?? 'pharmacy_${pharmacy.hashCode}'),
//           position: LatLng(pharmacy.latitude, pharmacy.longitude),
//           infoWindow: InfoWindow(
//             title: pharmacy.name,
//             snippet: '${pharmacy.address}\nDistance: ${distance.toStringAsFixed(1)} km',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           onTap: () {
//             if (widget.isSelectingLocation) {
//               setState(() {
//                 _selectedLocation = LatLng(pharmacy.latitude, pharmacy.longitude);
//               });
//               _setupMarkers();
//             } else {
//               _showPharmacyDetails(pharmacy, distance);
//             }
//           },
//         ),
//       );
//     }
//
//     // Add selected location marker
//     if (_selectedLocation != null && widget.isSelectingLocation) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('selected_location'),
//           position: _selectedLocation!,
//           infoWindow: const InfoWindow(title: 'Selected Location'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         ),
//       );
//     }
//   }
//
//   void _showPharmacyDetails(PharmacyModel pharmacy, double distance) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(pharmacy.name),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(pharmacy.address),
//             const SizedBox(height: 8),
//             Text('Phone: ${pharmacy.contactNumber}'),
//             Text('Distance: ${distance.toStringAsFixed(1)} km'),
//             const SizedBox(height: 8),
//             Text('Hours: ${pharmacy.openingHours}'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           if (widget.isSelectingLocation)
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _selectedLocation = LatLng(pharmacy.latitude, pharmacy.longitude);
//                 });
//                 Navigator.pop(context);
//                 _setupMarkers();
//               },
//               child: const Text('Select This Location'),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _onMapTap(LatLng position) {
//     if (widget.isSelectingLocation) {
//       setState(() {
//         _selectedLocation = position;
//       });
//       _setupMarkers();
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
//   void _confirmLocation() {
//     if (_selectedLocation != null && widget.onLocationSelected != null) {
//       widget.onLocationSelected!(_selectedLocation!);
//       Navigator.pop(context, _selectedLocation);
//     }
//   }
//
//   // Distance calculation method
//   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const R = 6371; // Earth radius in km
//     final dLat = _toRadians(lat2 - lat1);
//     final dLon = _toRadians(lon2 - lon1);
//
//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
//             sin(dLon / 2) * sin(dLon / 2);
//
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return R * c; // Distance in km
//   }
//
//   double _toRadians(double degree) {
//     return degree * pi / 180;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.isSelectingLocation ?
//         'Select Your Location' : 'Nearby Pharmacies'),
//         actions: [
//           if (widget.isSelectingLocation && _selectedLocation != null)
//             IconButton(
//               onPressed: _confirmLocation,
//               icon: const Icon(Icons.check),
//               tooltip: 'Confirm Location',
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: _currentLocation ??
//                   (widget.nearbyPharmacies.isNotEmpty
//                       ? LatLng(widget.nearbyPharmacies.first.latitude,
//                       widget.nearbyPharmacies.first.longitude)
//                       : const LatLng(0, 0)),
//               zoom: 14,
//             ),
//             markers: _markers,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             onTap: _onMapTap,
//           ),
//
//           // Location selection info
//           if (widget.isSelectingLocation && _selectedLocation != null)
//             Positioned(
//               top: 16,
//               left: 16,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Selected Location',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     Text(
//                       'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: _confirmLocation,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(double.infinity, 48),
//                       ),
//                       child: const Text('Confirm This Location'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _getCurrentLocation,
//         child: const Icon(Icons.my_location),
//       ),
//     );
//   }
// }