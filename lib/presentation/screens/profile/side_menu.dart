import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../history/ride_history_screen.dart';
import '../auth/login_screen.dart';
import 'emergency_contact_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = 'User';
  String _phoneNumber = '';

  bool _isLoadingUser = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  // ============================================================
  // LOAD USER DETAILS
  // ============================================================

  Future<void> _loadUserDetails() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });

      return;
    }

    final String phone = user.phoneNumber ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      final Map<String, dynamic>? data = doc.data();

      setState(() {
        _phoneNumber = phone;

        if (data != null && data['name'] != null) {
          final String savedName = data['name'].toString().trim();

          if (savedName.isNotEmpty) {
            _name = savedName;
          }
        }

        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint('Error loading user details: $e');

      if (!mounted) return;

      setState(() {
        _phoneNumber = phone;
        _isLoadingUser = false;
      });
    }
  }

  // ============================================================
  // EDIT NAME
  // ============================================================

  Future<void> _editName() async {
    final TextEditingController controller =
        TextEditingController(text: _name);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String name = controller.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your name'),
                    ),
                  );
                  return;
                }

                if (name.length < 2) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Name must contain at least 2 characters'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) return;

    await _updateName(newName);
  }

  // ============================================================
  // UPDATE NAME IN FIRESTORE
  // ============================================================

  Future<void> _updateName(String newName) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'name': newName,
          'phoneNumber': user.phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _name = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Name update error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to logout. Please try again.'),
        ),
      );
    }
  }

  // ============================================================
  // OPEN EMERGENCY CONTACT
  // ============================================================

  Future<void> _openEmergencyContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EmergencyContactScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN RIDE HISTORY
  // ============================================================

  Future<void> _openRideHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RideHistoryScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // USER HEADER
            // ======================================================

            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,

              accountName: Row(
                children: [
                  Expanded(
                    child: _isLoadingUser
                        ? const Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          )
                        : Text(
                            _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                  ),

                  IconButton(
                    tooltip: 'Edit name',
                    onPressed: _isLoadingUser ? null : _editName,
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),

              accountEmail: Text(
                _phoneNumber.isEmpty
                    ? 'Phone number not available'
                    : _phoneNumber,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
              ),

              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),

            // ======================================================
            // MENU
            // ======================================================

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ------------------------------------------------
                  // RIDE
                  // ------------------------------------------------

                  const ListTile(
                    leading: Icon(
                      Icons.directions_car,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Ride'),
                  ),

                  // ------------------------------------------------
                  // BOOKINGS
                  // ------------------------------------------------

                  const ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Bookings'),
                  ),

                  // ------------------------------------------------
                  // FAVORITES
                  // ------------------------------------------------

                  const ListTile(
                    leading: Icon(
                      Icons.star,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Favorites'),
                  ),

                  // ------------------------------------------------
                  // EMERGENCY CONTACT
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.emergency,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text('Emergency Contact'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: _openEmergencyContact,
                  ),

                  // ------------------------------------------------
                  // NOTIFICATIONS
                  // ------------------------------------------------

                  const ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Notifications'),
                  ),

                  // ------------------------------------------------
                  // PAYMENT METHODS
                  // ------------------------------------------------

                  const ListTile(
                    leading: Icon(
                      Icons.payment,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text('Payment Methods'),
                  ),

                  // ------------------------------------------------
                  // RIDE HISTORY
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text('Ride History'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: _openRideHistory,
                  ),

                  const Divider(),

                  // ------------------------------------------------
                  // LOGOUT
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text('Logout'),
                    trailing: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : null,
                    onTap: _isLoggingOut ? null : _logout,
                  ),
                ],
              ),
            ),

            // ======================================================
            // VERSION
            // ======================================================

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Version 3.0.10',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}