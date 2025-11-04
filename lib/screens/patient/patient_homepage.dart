import 'package:abc_app/screens/patient/medicine_detail_page.dart'; // <-- IMPORT THE DETAIL PAGE
import 'package:abc_app/screens/patient/notifications_page.dart'; // <-- IMPORT NOTIFICATIONS
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:abc_app/models/user_model.dart'; // Import your model
import 'package:flutter/material.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text("Error: Not logged in.")));
    }

    return CustomScrollView(
      slivers: [
        // 1. The Custom App Bar (StreamBuilder)
        StreamBuilder<DocumentSnapshot>(
            stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              UserModel? user;
              if (snapshot.hasData && snapshot.data!.exists) {
                user = UserModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);
              }

              // Fix for the AppBar image
              bool hasImage = (user != null && user.profileImageUrl.isNotEmpty);

              return SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 1,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                    hasImage ? NetworkImage(user!.profileImageUrl) : null,
                    child: !hasImage
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                title: Text(
                  user?.location ?? "Set your location",
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.call_outlined, color: Colors.red),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.grey),
                    onPressed: () {
                      // Navigate to Notifications Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                ],
              );
            }),

        // 2. The Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              color: Colors.transparent,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Medicines',
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
          ),
        ),

        // 3. The Banner Image
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                'assets/images/banner1.png', // Make sure this asset exists
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // 4. "Quick Access" Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              'Quick Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // 5. Quick Access Horizontal List
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .where('isFeatured', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No featured items.'));
                }

                var docs = snapshot.data!.docs;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String medicineId = docs[index].id; // <-- Get the ID

                    return _buildMedicineCard(
                      context,
                      data['medicineName'] ?? 'No Name',
                      data['category'] ?? 'No Category',
                      data['imageUrl'] ?? '',
                      medicineId, // <-- Pass the ID
                    );
                  },
                );
              },
            ),
          ),
        ),

        // 6. "All Medicines" Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              'All Medicines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // 7. Main Medicine Grid
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: Text('No medicines found.')),
              );
            }

            var docs = snapshot.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String medicineId = docs[index].id; // <-- Get the ID

                    return _buildMedicineCard(
                      context,
                      data['medicineName'] ?? 'No Name',
                      data['category'] ?? 'No Category',
                      data['imageUrl'] ?? '',
                      medicineId, // <-- Pass the ID
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  //
  // vvvv THIS IS THE UPDATED "UTIL" WIDGET vvvv
  //
  // Reusable widget for the medicine cards
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
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
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category,
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
