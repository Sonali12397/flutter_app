import 'package:abc_app/screens/patient/medicine_detail_page.dart'; // <-- IMPORT THE DETAIL PAGE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeSortFilter = 'none'; // 'none', 'priceLowToHigh', 'priceHighToLow'

  // This function builds the correct Firestore query based on the active sort filter
  Stream<QuerySnapshot> _buildMedicinesStream() {
    Query query = FirebaseFirestore.instance.collection('medicines');

    // Apply sorting based on the filter
    if (_activeSortFilter == 'priceLowToHigh') {
      query = query.orderBy('price', descending: false);
    } else if (_activeSortFilter == 'priceHighToLow') {
      query = query.orderBy('price', descending: true);
    }
    // If 'none', we just get the default (unsorted) collection

    return query.snapshots();
  }

  // Update the state when the search text changes
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Store'),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            _buildSearchBar(),

            // 2. Filter Chips
            _buildFilterChips(),

            // 3. Banners
            _buildBanners(),

            // 4. "Recommended Medicines" Title
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Recommended Medicines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // 5. Dynamic Medicine Grid
            _buildMedicinesGrid(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER FUNCTIONS ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        color: Colors.transparent, // Fix for "No Material" error
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medicines or health products',
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
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          _buildFilterChip("Nearest Location", 'nearest'),
          _buildFilterChip("Price: Low to High", 'priceLowToHigh'),
          _buildFilterChip("Price: High to Low", 'priceHighToLow'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final bool isSelected = _activeSortFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (filterKey == 'nearest') {
            // TODO: Add location-based sorting logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Location sorting not implemented yet.')),
            );
            return;
          }

          setState(() {
            if (selected) {
              _activeSortFilter = filterKey;
            } else {
              _activeSortFilter = 'none'; // Deselecting reverts to 'none'
            }
          });
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
    );
  }

  Widget _buildBanners() {
    // You can make this dynamic from a 'banners' collection in Firestore
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: [
          _buildBannerCard("Flat 20% Off", 'assets/images/banner1.png'),
          _buildBannerCard("Free Delivery", 'assets/images/banner2.png'),
        ],
      ),
    );
  }

  Widget _buildBannerCard(String title, String imagePath) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath, // Make sure to add these to your assets
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesGrid() {
    return StreamBuilder<QuerySnapshot>(
      // We call the function here so the stream rebuilds when the filter changes
      stream: _buildMedicinesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No medicines found.'));
        }

        // --- CLIENT-SIDE SEARCH LOGIC ---
        var allDocs = snapshot.data!.docs;

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final medicineName = data['medicineName']?.toLowerCase() ?? '';

          if (_searchQuery.isEmpty) {
            return true;
          } else {
            return medicineName.contains(_searchQuery.toLowerCase());
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No medicines match your search.'),
          );
        }
        // ----------------------------------

        return GridView.builder(
          itemCount: filteredDocs.length,
          shrinkWrap: true, // Required inside SingleChildScrollView
          physics:
          const NeverScrollableScrollPhysics(), // Required inside SingleChildScrollView
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 0.75, // Adjust item proportions
          ),
          itemBuilder: (context, index) {
            var data = filteredDocs[index].data() as Map<String, dynamic>;
            String medicineId = filteredDocs[index].id; // <-- Get the ID

            num price = data['price'] ?? 0.0;
            String medicineName = data['medicineName'] ?? 'No Name';
            String imageUrl = data['imageUrl'] ?? '';
            String category = data['category'] ?? ''; // Get category

            return _buildMedicineCard(
              context,
              medicineName,
              category, // Pass category
              imageUrl,
              medicineId, // Pass the ID
            );
          },
        );
      },
    );
  }

  //
  // vvvv THIS IS THE UPDATED "UTIL" WIDGET vvvv
  //
  Widget _buildMedicineCard(
      BuildContext context, String name, String category, String imageUrl, String medicineId) { // <-- Added medicineId

    bool hasImage = imageUrl.isNotEmpty;

    // Wrap the Card in a GestureDetector to make it clickable
    return GestureDetector(
      onTap: () {
        // Navigate to the MedicineDetailPage and pass the ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(medicineId: medicineId),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: hasImage
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  )
                      : Icon( // Placeholder if no image
                    Icons.medication_liquid,
                    color: Colors.grey[300],
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category, // Show category here
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
