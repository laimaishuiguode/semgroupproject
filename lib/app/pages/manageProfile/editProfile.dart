import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../manageWorkingSchedule/WorkScheduleList.dart';
import '../manageInventory/inventoryList.dart';
import '../managePayment/paymentinterface.dart';
import '../manageRating/ratingDashboard.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _icController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'Male';
  String _role = 'Owner'; 
  String _countryCode = '+60';// Default fallback
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _countryCode = data['countryCode'] ?? '+60';
        _phoneController.text = data['phoneNumber'] ?? '';
        _icController.text = data['ic'] ?? '';
        _addressController.text = data['address'] ?? '';
        _gender = data['gender'] ?? 'Male';
        _role = data['role'] ?? 'Owner';
        _imagePath = data['imagePath'];
        if (_imagePath != null && File(_imagePath!).existsSync()) {
          _imageFile = File(_imagePath!);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = picked.path;
      });
    }
  }


    String? validateIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter IC number';
    }

    final ic = value.replaceAll(RegExp(r'\D'), '');

    if (ic.length != 12) {
      return 'IC must be exactly 12 digits';
    }

    // birth date YYMMDD
    final yy = int.parse(ic.substring(0, 2));
    final mm = int.parse(ic.substring(2, 4));
    final dd = int.parse(ic.substring(4, 6));

    final fullYear = (yy <= (DateTime.now().year % 100))
        ? 2000 + yy
        : 1900 + yy;

    final date = DateTime.tryParse(
        '$fullYear-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}');

    if (date == null) {
      return 'Invalid birth date';
    }

    // state code
    final stateCode = ic.substring(6, 8);

    const validStates = {
      '01','02','03','04','05','06','07','08','09',
      '10','11','12','13','14','15','16'
    };

    if (!validStates.contains(stateCode)) {
      return 'Invalid state code';
    }

    return null;
  }
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'name': _nameController.text.trim(),
        'countryCode': _countryCode,
        'phone': _phoneController.text.trim(),
        'ic': _icController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        if (_imagePath != null) 'imagePath': _imagePath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context); // back to OwnerHomePage
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerCalendarPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InventoryListPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentInterface()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RatingDashboardPage(userRole: _role.toLowerCase()),
        ),
      );
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.getRoleColor(_role);
    return Theme(
      data: AppTheme.getTheme(_role),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          title: const Text('FixUp Pro'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter name' : null,
                          ),
                          Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                value: _countryCode,
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: '+60',
                                    child: Text('🇲🇾 +60'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+65',
                                    child: Text('🇸🇬 +65'),
                                  ),
                                  DropdownMenuItem(
                                    value: '+62',
                                    child: Text('🇮🇩 +62'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _countryCode = value!;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                ),
                                keyboardType: TextInputType.phone,

                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
                                  }

                                  final phone =
                                      value.replaceAll(RegExp(r'\D'), '');

                                  if (_countryCode == '+60') {
                                    if (phone.length < 9 || phone.length > 10) {
                                      return 'Malaysia phone number must be 9-10 digits';
                                    }
                                  }

                                  if (_countryCode == '+65') {
                                    if (phone.length != 8) {
                                      return 'Singapore phone number must be 8 digits';
                                    }
                                  }

                                  if (_countryCode == '+62') {
                                    if (phone.length < 9 || phone.length > 13) {
                                      return 'Indonesia phone number must be 9-13 digits';
                                    }
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                          TextFormField(
                            controller: _icController,
                            decoration: const InputDecoration(
                                labelText: 'IC Number (No Dashes, must be 12 digits number)'),
                            keyboardType: TextInputType.number,
                            validator: validateIC
                          ),
                          TextFormField(
                            controller: _addressController,
                            decoration:
                                const InputDecoration(labelText: 'Address'),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter address' : null,
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Gender'),
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'Male',
                                groupValue: _gender,
                                onChanged: (value) =>
                                    setState(() => _gender = value!),
                              ),
                              const Text('Male'),
                              Radio<String>(
                                value: 'Female',
                                groupValue: _gender,
                                onChanged: (value) =>
                                    setState(() => _gender = value!),
                              ),
                              const Text('Female'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                            ),
                            child: const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.work), label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payment), label: 'Payments'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rating'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
    );
  }
}