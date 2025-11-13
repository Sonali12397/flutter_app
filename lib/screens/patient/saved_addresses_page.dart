import 'package:abc_app/models/address_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'add_address_page.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  // Helper to get the correct icon based on the title
  IconData _getIconForTitle(String title) {
    String lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('home')) {
      return Icons.home_outlined;
    } else if (lowerTitle.contains('office') || lowerTitle.contains('work')) {
      return Icons.work_outline;
    }
    return Icons.location_on_outlined; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAddressPage(),
                  ),
                );
              },
              child: const Text('Add New', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AddressModel>>(
        stream: firestoreService.getAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No Saved Addresses', style: TextStyle(fontSize: 20)),
                  const Text('Add a new address to get started.'),
                ],
              ),
            );
          }

          final addresses = snapshot.data!;
          // Find the ID of the default address
          final String defaultAddressId = addresses
              .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
              .id!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final fullAddress =
                  '${address.addressLine1}, ${address.city}, ${address.stateRegion} ${address.postalCode}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIconForTitle(address.title),
                            color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullAddress,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: address.id!,
                        groupValue: defaultAddressId,
                        onChanged: (String? value) {
                          if (value != null) {
                            firestoreService.setDefaultAddress(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}