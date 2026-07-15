import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parlour_provider.dart';
import '../../widgets/bottom_nav.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isEditing = false;

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _birthdayController;
  late TextEditingController _ageController;
  
  // 5 Quiz/Diagnosis individual responses controllers
  late TextEditingController _skinTypeController;
  late TextEditingController _skinConcernsController;
  late TextEditingController _hairTypeController;
  late TextEditingController _hairConcernsController;
  late TextEditingController _beautyGoalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _birthdayController = TextEditingController();
    _ageController = TextEditingController();
    
    _skinTypeController = TextEditingController();
    _skinConcernsController = TextEditingController();
    _hairTypeController = TextEditingController();
    _hairConcernsController = TextEditingController();
    _beautyGoalController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    
    _skinTypeController.dispose();
    _skinConcernsController.dispose();
    _hairTypeController.dispose();
    _hairConcernsController.dispose();
    _beautyGoalController.dispose();
    super.dispose();
  }

  void _initFields(dynamic customer) {
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _emailController.text = customer.email;
    _birthdayController.text = customer.birthday;
    _ageController.text = customer.age.toString();
    
    _skinTypeController.text = customer.skinType;
    _skinConcernsController.text = customer.skinConcerns;
    _hairTypeController.text = customer.hairType;
    _hairConcernsController.text = customer.hairConcerns;
    _beautyGoalController.text = customer.beautyGoal;
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    final newAge = int.tryParse(_ageController.text.trim()) ?? auth.currentUser!.age;
    
    await auth.updateProfileDetails(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      birthday: _birthdayController.text.trim(),
      age: newAge,
      skinType: _skinTypeController.text.trim(),
      hairType: _hairTypeController.text.trim(),
      skinConcerns: _skinConcernsController.text.trim(),
      hairConcerns: _hairConcernsController.text.trim(),
      beautyGoal: _beautyGoalController.text.trim(),
    );

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile details updated successfully!"),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final parlour = Provider.of<ParlourProvider>(context);

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customer = parlour.customers.firstWhere(
      (c) => c.id == user.id,
      orElse: () => user,
    );

    // Only populate controllers if not editing (keeps typing data safe)
    if (!_isEditing) {
      _initFields(customer);
    }

    // Bookings count details
    final userBookings = parlour.bookings.where(
      (b) => b.customerEmail.trim().toLowerCase() == user.email.trim().toLowerCase() ||
             (b.customerPhone.isNotEmpty && user.phone.isNotEmpty && b.customerPhone.trim() == user.phone.trim())
    ).toList();
    final upcomingCount = userBookings.where((b) => b.status == 'Confirmed' || b.status == 'Pending').length;
    final pastCount = userBookings.where((b) => b.status == 'History').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
          onPressed: () => context.go('/customer/dashboard'),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile(auth);
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            child: Text(
              _isEditing ? "Save" : "Edit",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Color(0xFFFFECEF), thickness: 1.5, height: 1),
              const SizedBox(height: 24),

              // Profile Hero Avatar section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: ClipOval(
                            child: Image.network(
                              "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // Centered Name layout
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            hintText: "Enter Name",
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                          ),
                        ),
                      )
                    else
                      Text(
                        customer.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                      ),
                      
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            customer.badge,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Member Since ${customer.memberSince}",
                          style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Stats Row (Upcoming, Past visits, Points capsule)
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(upcomingCount.toString(), "Upcomings"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(pastCount.toString(), "Past Visits"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(customer.points.toString(), "Points", highlight: true),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Personal Details Header
              const Text(
                "Personal Details",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                ),
                child: Column(
                  children: [
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.phone, "Phone", _phoneController, keyboardType: TextInputType.phone)
                        : _buildTextDetailRow(LucideIcons.phone, "Phone", customer.phone.isNotEmpty ? customer.phone : "+91 1234567890"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
                    
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.mail, "email", _emailController, keyboardType: TextInputType.emailAddress)
                        : _buildTextDetailRow(LucideIcons.mail, "email", customer.email.isNotEmpty ? customer.email : "example@gmail.com", isUnderlined: true),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
                    
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.gift, "Birthday", _birthdayController)
                        : _buildTextDetailRow(LucideIcons.gift, "Birthday", customer.birthday.isNotEmpty ? customer.birthday : "Jan 14"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
                    
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.user, "Age", _ageController, keyboardType: TextInputType.number)
                        : _buildTextDetailRow(LucideIcons.user, "Age", "${customer.age} Years Old"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Skin & Hair Diagnostics - 5 Quiz Answers
              const Text(
                "Diagnostics & Profiles",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                ),
                child: Column(
                  children: [
                    // 1. Skin Type
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.smile, "Skin Type", _skinTypeController)
                        : _buildTextDetailRow(LucideIcons.smile, "Skin Type", customer.skinType.isNotEmpty ? customer.skinType : "Normal"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
                    
                    // 2. Skin Concerns
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.sparkles, "Skin Concerns", _skinConcernsController)
                        : _buildTextDetailRow(LucideIcons.sparkles, "Skin Concerns", customer.skinConcerns.isNotEmpty ? customer.skinConcerns : "None"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),

                    // 3. Hair Type
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.scissors, "Hair Type", _hairTypeController)
                        : _buildTextDetailRow(LucideIcons.scissors, "Hair Type", customer.hairType.isNotEmpty ? customer.hairType : "Straight"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),

                    // 4. Hair Concerns
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.frown, "Hair Concerns", _hairConcernsController)
                        : _buildTextDetailRow(LucideIcons.frown, "Hair Concerns", customer.hairConcerns.isNotEmpty ? customer.hairConcerns : "None"),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),

                    // 5. Beauty Goals
                    _isEditing
                        ? _buildEditableDetailRow(LucideIcons.award, "Beauty Goals", _beautyGoalController)
                        : _buildTextDetailRow(LucideIcons.award, "Beauty Goals", customer.beautyGoal.isNotEmpty ? customer.beautyGoal : "Routine Grooming"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings & Info
              const Text(
                "Settings & Support",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildActionDetailRow(LucideIcons.bell, "Notifications", null, hasDot: true),
                    const Divider(color: Color(0xFFFFECEF), height: 1, thickness: 1.5),
                    _buildActionDetailRow(LucideIcons.helpCircle, "Help & Support", null),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Log Out link button
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(activeTab: 'profile'),
    );
  }

  Widget _buildStatItem(String val, String lbl, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppTheme.primary : const Color(0xFFFFECEF),
          width: 1.5,
        ),
        boxShadow: highlight ? [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : AppTheme.darkText,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lbl,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.white70 : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDetailRow(IconData icon, String label, String value, {bool isUnderlined = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                    decoration: isUnderlined ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailRow(
    IconData icon,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFECEF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDetailRow(IconData icon, String label, String? value, {bool hasDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          if (hasDot)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.lightText),
        ],
      ),
    );
  }
}
