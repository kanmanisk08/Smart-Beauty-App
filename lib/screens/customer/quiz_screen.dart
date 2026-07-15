import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class CustomerQuizScreen extends StatefulWidget {
  const CustomerQuizScreen({super.key});

  @override
  State<CustomerQuizScreen> createState() => _CustomerQuizScreenState();
}

class _CustomerQuizScreenState extends State<CustomerQuizScreen> {
  int _currentStep = 0;

  // Selected values
  String _selectedHairType = 'Straight';
  String _selectedSkinType = 'Normal';
  final List<String> _selectedHairConcerns = [];
  final List<String> _selectedSkinConcerns = [];
  String _selectedBeautyGoal = 'Routine Grooming';

  final List<Map<String, String>> _hairTypes = [
    {'name': 'Straight', 'desc': 'Silky & flat', 'emoji': '💁‍♀️'},
    {'name': 'Wavy', 'desc': 'S-shaped body', 'emoji': '🌊'},
    {'name': 'Curly', 'desc': 'Springy spirals', 'emoji': '🌀'},
    {'name': 'Coily', 'desc': 'Tight zig-zags', 'emoji': '🧬'},
  ];

  final List<Map<String, String>> _skinTypes = [
    {'name': 'Dry', 'desc': 'Flakey/Tight', 'emoji': '🌵'},
    {'name': 'Oily', 'desc': 'Shiny/Pores', 'emoji': '✨'},
    {'name': 'Normal', 'desc': 'Balanced glow', 'emoji': '🌸'},
    {'name': 'Sensitive', 'desc': 'Redness/Itch', 'emoji': '🛡️'},
    {'name': 'Combination', 'desc': 'Oily T-zone', 'emoji': '⚖️'},
  ];

  final List<String> _hairConcernsOptions = [
    'Hair Fall',
    'Dry & Frizzy',
    'Split Ends',
    'Dandruff',
    'Damage',
  ];

  final List<String> _skinConcernsOptions = [
    'Acne/Pimples',
    'Dullness',
    'Dark Circles',
    'Wrinkles',
    'Redness',
  ];

  final List<Map<String, String>> _beautyGoals = [
    {'name': 'Routine Grooming', 'desc': 'Maintenance & shine', 'emoji': '💅'},
    {'name': 'Bridal/Event Prep', 'desc': 'Glow for the big day', 'emoji': '👰‍♀️'},
    {'name': 'Anti-Aging Care', 'desc': 'Rejuvenate & firm', 'emoji': '💆‍♀️'},
    {'name': 'Deep Hydration', 'desc': 'Replenish moisture', 'emoji': '💧'},
    {'name': 'Hair Repair', 'desc': 'Strengthen roots', 'emoji': '🌿'},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final String finalSkinConcerns = _selectedSkinConcerns.isNotEmpty ? _selectedSkinConcerns.join(', ') : 'None';
    final String finalHairConcerns = _selectedHairConcerns.isNotEmpty ? _selectedHairConcerns.join(', ') : 'None';

    await auth.updateDiagnostics(
      skinType: _selectedSkinType,
      hairType: _selectedHairType,
      skinConcerns: finalSkinConcerns,
      hairConcerns: finalHairConcerns,
      beautyGoal: _selectedBeautyGoal,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Diagnostic profile set up! Welcome to Selvi's!"),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go('/customer/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkText, size: 20),
                onPressed: _prevStep,
              )
            : null,
        title: const Text(
          "Personalized Diagnostics",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go('/customer/dashboard'),
            child: const Text(
              "Skip",
              style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Step tracker (5 questions now)
              Row(
                children: List.generate(5, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                "QUESTION ${_currentStep + 1} OF 5",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 20),

              // Animated Transition Container for Question Card
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildQuizContent(),
                  ),
                ),
              ),

              // Bottom control buttons
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFFECEF), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 4 ? "Let's Get Started" : "Continue",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(_currentStep == 4 ? Icons.check : Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    switch (_currentStep) {
      case 0:
        return _buildGridStep(
          title: "Select your hair type",
          subtitle: "Enables custom haircut & hair treatment mapping.",
          options: _hairTypes,
          selected: _selectedHairType,
          onSelect: (val) => setState(() => _selectedHairType = val),
        );
      case 1:
        return _buildGridStep(
          title: "Select your skin type",
          subtitle: "Critical for custom cleanups, facials & masks.",
          options: _skinTypes,
          selected: _selectedSkinType,
          onSelect: (val) => setState(() => _selectedSkinType = val),
        );
      case 2:
        return _buildWrapConcernsStep(
          title: "Any hair concerns?",
          subtitle: "Pick focus areas for your treatments.",
          options: _hairConcernsOptions,
          selectedList: _selectedHairConcerns,
          iconData: LucideIcons.scissors,
          illustration: '💇‍♀️',
        );
      case 3:
        return _buildWrapConcernsStep(
          title: "Any skin concerns?",
          subtitle: "We custom-mix organic creams to target these.",
          options: _skinConcernsOptions,
          selectedList: _selectedSkinConcerns,
          iconData: LucideIcons.sparkles,
          illustration: '✨',
        );
      case 4:
        return _buildGridStep(
          title: "Primary beauty goal?",
          subtitle: "Helps Selvi recommend the best package focus.",
          options: _beautyGoals,
          selected: _selectedBeautyGoal,
          onSelect: (val) => setState(() => _selectedBeautyGoal = val),
        );
      default:
        return const SizedBox();
    }
  }

  // Grid style selection for Step 1 & 2 (No scroll, Centered)
  Widget _buildGridStep({
    required String title,
    required String subtitle,
    required List<Map<String, String>> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Fits screen
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final isSelected = selected == opt['name'];
            return GestureDetector(
              onTap: () => onSelect(opt['name']!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
                    width: isSelected ? 2.0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      opt['emoji']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt['name']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: AppTheme.lightText, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Visual wrap-tag selector for Concerns (Step 3 & 4 - Centered)
  Widget _buildWrapConcernsStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedList,
    required IconData iconData,
    required String illustration,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.lightText, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        
        // Large visual centerpiece
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              illustration,
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Cloud of tags wrap (Fits perfectly without list scroll)
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: options.map((opt) {
              final isSelected = selectedList.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedList.remove(opt);
                    } else {
                      selectedList.add(opt);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : const Color(0xFFFFECEF),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check : iconData,
                        color: isSelected ? Colors.white : AppTheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
