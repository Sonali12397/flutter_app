import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/screens/pharmacy/add_medicine_page.dart';
import 'package:abc_app/screens/pharmacy/update_medicine_page.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

import '../common/profile_page.dart';

class PharmacyHomepage extends StatefulWidget {
  const PharmacyHomepage({super.key});

  @override
  State<PharmacyHomepage> createState() => _PharmacyHomepageState();
}

class _PharmacyHomepageState extends State<PharmacyHomepage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // vvvv NEW STATE FOR FILTERING vvvv
  String _activeFilter = 'all'; // 'all', 'inStock', 'lowStock', 'outOfStock'
  // ^^^^ NEW STATE FOR FILTERING ^^^^

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // vvvv NEW FUNCTION TO SET FILTER vvvv
  void _setFilter(String filterKey) {
    setState(() {
      if (_activeFilter == filterKey) {
        _activeFilter = 'all'; // If tapping the same one, clear filter
      } else {
        _activeFilter = filterKey;
      }
    });
  }
  // ^^^^ NEW FUNCTION TO SET FILTER ^^^^

  @override
  Widget build(BuildContext context) {
    // This StreamBuilder fetches the Pharmacy's own profile data for the AppBar
    return StreamBuilder<UserModel>(
      stream: _firestoreService.getCurrentUserStream(),
      builder: (context, userSnapshot) {
        // This makes your AppBar profile icon dynamic
        Widget leadingAvatar;
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          leadingAvatar = const CircleAvatar(backgroundColor: Colors.transparent);
        } else if (userSnapshot.hasData &&
            userSnapshot.data!.profileImageUrl.isNotEmpty) {
          // If user has a profile image, show it
          leadingAvatar = CircleAvatar(
            backgroundImage: NetworkImage(userSnapshot.data!.profileImageUrl),
          );
        } else {
          // Otherwise, show a placeholder icon
          leadingAvatar = CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text('MediCare Pharmacy',
                style: TextStyle(color: Colors.black)),
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              // This makes the avatar clickable and navigates to ProfilePage
              child: GestureDetector(
                onTap: () {
                  // This is your requested feature:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  ProfilePage()),
                  );
                },
                child: leadingAvatar, // Use the dynamic avatar
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: StreamBuilder<List<MedicineModel>>(
            stream: _firestoreService.getPharmacyMedicines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              // We have data, let's process it
              final allMedicines = snapshot.data!;

              // Calculate stats
              int inStockCount = allMedicines.where((m) => m.quantity > 30).length;
              int lowStockCount = allMedicines
                  .where((m) => m.quantity > 0 && m.quantity <= 30)
                  .length;
              int outOfStockCount = allMedicines.where((m) => m.quantity == 0).length;

              // vvvv UPDATED FILTERING LOGIC vvvv
              // 1. First, filter by the active stat card
              List<MedicineModel> filteredByStock;
              if (_activeFilter == 'inStock') {
                filteredByStock = allMedicines.where((m) => m.quantity > 30).toList();
              } else if (_activeFilter == 'lowStock') {
                filteredByStock = allMedicines.where((m) => m.quantity > 0 && m.quantity <= 30).toList();
              } else if (_activeFilter == 'outOfStock') {
                filteredByStock = allMedicines.where((m) => m.quantity == 0).toList();
              } else {
                filteredByStock = allMedicines; // 'all'
              }

              // 2. Then, filter by the search query
              final filteredMedicines = filteredByStock.where((m) {
                return m.medicineName.toLowerCase().contains(_searchQuery);
              }).toList();
              // ^^^^ UPDATED FILTERING LOGIC ^^^^

              return CustomScrollView(
                slivers: [
                  // Header with Stats
                  SliverToBoxAdapter(
                    child: _buildHeader(inStockCount, lowStockCount, outOfStockCount),
                  ),

                  // Search and Add Button
                  SliverToBoxAdapter(
                    child: _buildSearchAndAdd(),
                  ),

                  // Inventory Title
                  SliverToBoxAdapter(
                    child: _buildInventoryTitle(),
                  ),

                  // Inventory List
                  _buildInventoryList(filteredMedicines),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Your inventory is empty.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Medicine'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicinePage()),
              );
            },
          )
        ],
      ),
    );
  }

  // vvvv UPDATED vvvv
  Widget _buildHeader(int inStock, int lowStock, int outOfStock) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'In Stock', inStock.toString(), const Color(0xFF4DD0E1),
                filterKey: 'inStock', // <-- Pass key
                onTap: () => _setFilter('inStock'), // <-- Pass tap handler
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Low Stock', lowStock.toString(), const Color(0xFF4DD0E1),
                filterKey: 'lowStock', // <-- Pass key
                onTap: () => _setFilter('lowStock'), // <-- Pass tap handler
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Out of Stock', outOfStock.toString(), const Color(0xFF4DD0E1),
            isFullWidth: true,
            filterKey: 'outOfStock', // <-- Pass key
            onTap: () => _setFilter('outOfStock'), // <-- Pass tap handler
          ),
        ],
      ),
    );
  }

  // vvvv UPDATED vvvv
  Widget _buildStatCard(String title, String count, Color color,
      {bool isFullWidth = false, required String filterKey, required VoidCallback onTap}) {

    // Check if this card is the selected one
    final bool isSelected = _activeFilter == filterKey;
    // Check if *any* filter is active, but not this one (for fading)
    final bool isFaded = _activeFilter != 'all' && !isSelected;

    Widget cardContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isFaded ? 0.5 : 1.0, // Fade if not selected
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          // Add border if this card is selected
          border: isSelected
              ? Border.all(color: Colors.blue.shade900, width: 3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(count,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    // Make the card clickable
    Widget clickableCard = GestureDetector(
      onTap: onTap,
      child: cardContent,
    );

    return isFullWidth ? clickableCard : Expanded(child: clickableCard);
  }

  Widget _buildSearchAndAdd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'), // Shorter text
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicinePage()),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildInventoryTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Inventory',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          // Add a "Show All" button that only appears if a filter is active
          if (_activeFilter != 'all')
            TextButton(
              onPressed: () => _setFilter('all'),
              child: const Text('Show All'),
            )
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<MedicineModel> medicines) {
    if (medicines.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No medicines found for this filter.', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final medicine = medicines[index];
          return _buildInventoryItem(medicine);
        },
        childCount: medicines.length,
      ),
    );
  }

  Widget _buildInventoryItem(MedicineModel medicine) {
    String stockStatus;
    Color stockColor;
    if (medicine.quantity == 0) {
      stockStatus = 'Out of Stock';
      stockColor = Colors.red;
    } else if (medicine.quantity <= 30) {
      stockStatus = 'Low Stock';
      stockColor = Colors.orange;
    } else {
      stockStatus = 'In Stock';
      stockColor = Colors.green;
    }

    bool hasImage = medicine.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Card
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stockStatus,
                          style: TextStyle(
                              color: stockColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Text(medicine.medicineName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        // Safe substring check for description
                        '${medicine.category} • ${medicine.description.length > 20 ? medicine.description.substring(0, 20) : medicine.description}...',
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Price Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹ ${medicine.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dynamic Image Widget
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasImage
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      medicine.imageUrl, // Load image from URL
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                      const Icon(Icons.error, color: Colors.red),
                    ),
                  )
                      : const Icon( // Show placeholder if no URL
                    Icons.medication_liquid,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit/Delete Buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UpdateMedicinePage(medicine: medicine),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onPressed: () => _showDeleteDialog(medicine.id!),
                    ),
                  ],
                ),
                // Quantity Title
                Text('Quantity: ${medicine.quantity}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),

                // Quantity Buttons
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed: medicine.quantity == 0
                          ? null
                          : () {
                        _firestoreService.updateMedicineQuantity(
                            medicine.id!, medicine.quantity - 1);
                      },
                    ),
                    SizedBox(
                        width: 24, // Give it a bit more space
                        child: Center(
                            child: Text(medicine.quantity.toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)))),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed: () {
                        _firestoreService.updateMedicineQuantity(
                            medicine.id!, medicine.quantity + 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[200] : Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: onPressed == null ? Colors.grey[400] : Colors.blue[800]),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        required String label,
        required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String medicineId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text(
            'Are you sure you want to delete this item from your inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _firestoreService.deleteMedicine(medicineId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
