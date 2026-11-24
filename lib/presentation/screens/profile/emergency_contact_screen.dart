import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../widgets/custom_button.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState
    extends State<EmergencyContactScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContact();
  }

  Future<void> loadContact() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      final doc = await _firestore
          .collection('emergency_contacts')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        nameController.text =
            data?['name'] ?? '';

        phoneController.text =
            data?['phone'] ?? '';
      }
    } catch (e) {
      debugPrint("Load Contact Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveContact() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      await _firestore
          .collection('emergency_contacts')
          .doc(user.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Emergency Contact Saved"),
        ),
      );
    } catch (e) {
      debugPrint("Save Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Failed to save contact"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Emergency Contact")),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(
                      hintText: "Contact Name",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    keyboardType:
                        TextInputType.phone,
                    decoration:
                        const InputDecoration(
                      hintText: "Phone Number",
                    ),
                  ),

                  const SizedBox(height: 30),

                  CustomButton(
                    text: "Save Contact",
                    onPressed: saveContact,
                  ),
                ],
              ),
            ),
    );
  }
}