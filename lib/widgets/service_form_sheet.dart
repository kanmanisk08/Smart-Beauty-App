import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/service.dart';
import '../providers/parlour_provider.dart';

/// Bottom sheet for adding a new service, or editing an existing one.
///
/// Pass [existing] to edit — in that mode the description is intentionally
/// omitted: it is set once when the service is created and shown read-only on
/// the detail page.
Future<void> showServiceFormSheet(BuildContext context, {Service? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: Provider.of<ParlourProvider>(context, listen: false),
      child: _ServiceFormSheet(existing: existing),
    ),
  );
}

class _ServiceFormSheet extends StatefulWidget {
  final Service? existing;
  const _ServiceFormSheet({this.existing});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late String _category;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _price = TextEditingController(text: s != null ? s.price.toInt().toString() : '');
    _duration = TextEditingController(text: s != null ? s.duration.toString() : '');
    _description = TextEditingController(text: s?.description ?? '');
    _isActive = s?.isActive ?? true;

    final parlour = Provider.of<ParlourProvider>(context, listen: false);
    final categories = parlour.serviceCategories;
    _category = s?.category ?? (categories.isNotEmpty ? categories.first : 'Haircuts & Styling');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final parlour = Provider.of<ParlourProvider>(context, listen: false);
    final name = _name.text.trim();
    final price = double.parse(_price.text.trim());
    final duration = int.parse(_duration.text.trim());

    if (_isEditing) {
      await parlour.updateServiceDetails(
        widget.existing!.id,
        name: name,
        category: _category,
        price: price,
        duration: duration,
        isActive: _isActive,
      );
    } else {
      await parlour.addService(
        name: name,
        category: _category,
        price: price,
        duration: duration,
        description: _description.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? '"$name" updated.' : '"$name" added to your catalogue.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parlour = Provider.of<ParlourProvider>(context);
    final categories = {...parlour.serviceCategories, _category}.toList()..sort();

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD4DA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? "Edit Service" : "Add New Service",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? "Update the details customers see when booking."
                      : "It appears in the customer catalogue straight away.",
                  style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
                ),
                const SizedBox(height: 20),

                _label("Service name"),
                _field(
                  controller: _name,
                  hint: "e.g. Keratin Treatment",
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Give the service a name" : null,
                ),
                const SizedBox(height: 16),

                _label("Category"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.lightText),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkText),
                      items: [
                        ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        const DropdownMenuItem(value: _newCategorySentinel, child: Text("+ New category…")),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        if (v == _newCategorySentinel) {
                          _promptNewCategory();
                        } else {
                          setState(() => _category = v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label("Price (Rs.)"),
                          _field(
                            controller: _price,
                            hint: "500",
                            keyboardType: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              final n = double.tryParse((v ?? '').trim());
                              if (n == null) return "Enter a price";
                              if (n <= 0) return "Must be above 0";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label("Duration (min)"),
                          _field(
                            controller: _duration,
                            hint: "45",
                            keyboardType: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return "Enter minutes";
                              if (n <= 0) return "Must be above 0";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description is only offered when creating the service.
                if (!_isEditing) ...[
                  const SizedBox(height: 16),
                  _label("Description"),
                  _field(
                    controller: _description,
                    hint: "What the treatment includes…",
                    maxLines: 3,
                  ),
                ],

                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFECEF), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Visible to customers",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkText),
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          activeColor: AppTheme.primary,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFECEF), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEditing ? "Save Changes" : "Add Service",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _newCategorySentinel = '__new__';

  Future<void> _promptNewCategory() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New category"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. Spa & Massage"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text("Add", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (created != null && created.isNotEmpty && mounted) {
      setState(() => _category = created);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkText),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black26, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(const Color(0xFFFFECEF)),
        enabledBorder: _border(const Color(0xFFFFECEF)),
        focusedBorder: _border(AppTheme.primary),
        errorBorder: _border(AppTheme.danger),
        focusedErrorBorder: _border(AppTheme.danger),
        errorStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
