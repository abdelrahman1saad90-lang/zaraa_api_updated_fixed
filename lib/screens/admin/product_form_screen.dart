import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/models/admin/product_request_model.dart';
import '../../cubits/admin/admin_products_cubit.dart';
import '../../cubits/category/category_cubit.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  const ProductFormScreen({super.key, this.existingProduct});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _brandIdCtrl = TextEditingController();

  bool _status = true;
  bool _isSubmitting = false;
  int? _selectedCategoryId;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool get _isEdit => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existingProduct!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price.toString();
      _quantityCtrl.text = p.quantity.toString();
      _discountCtrl.text = p.discount.toString();
      _status = !p.isSoldOut;
      _selectedCategoryId = p.categoryId;
      _brandIdCtrl.text = '1';
    }

    // Ensure categories are loaded
    final catState = context.read<CategoryCubit>().state;
    if (catState is! CategoryLoaded) {
      context.read<CategoryCubit>().loadCategories();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _discountCtrl.dispose();
    _brandIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFile != null && mounted) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    if (!_isEdit && _selectedImage == null) {
      _showSnackBar('Please select a product image', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final requestData = ProductRequestModel(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      status: _status,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 0,
      discount: double.tryParse(_discountCtrl.text.trim()) ?? 0,
      categoryId: _selectedCategoryId!,
      brandId: int.tryParse(_brandIdCtrl.text.trim()) ?? 1,
      mainImgPath: _selectedImage?.path,
    );

    bool success;
    if (!_isEdit) {
      success = await context.read<AdminProductsCubit>().createProduct(requestData);
    } else {
      success = await context.read<AdminProductsCubit>().updateProduct(
        int.parse(widget.existingProduct!.id),
        requestData,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.pop();
    }
    // On error, the Cubit has already emitted AdminProductsError state.
    // The BlocListener in ProductsManagementScreen will show the snackbar.
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminProductsCubit, AdminProductsState>(
      listener: (context, state) {
        if (state is AdminProductsError) {
          _showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Product' : 'Create Product'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Picker ──────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _pickImage,
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildImageWidget(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : _pickImage,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text(_selectedImage != null ? 'Change Image' : 'Select Image'),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form Fields ───────────────────────────────────
                _buildSectionLabel('Product Information'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Product Name', Icons.label_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descCtrl,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Description (optional)', Icons.description_rounded),
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Pricing & Stock'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Price (EGP)', Icons.attach_money_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid number';
                          if (double.parse(v.trim()) < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Quantity', Icons.inventory_2_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Whole number only';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Discount (%)', Icons.discount_rounded),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // optional
                          final d = double.tryParse(v.trim());
                          if (d == null) return 'Invalid number';
                          if (d < 0 || d > 100) return 'Must be 0–100';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _brandIdCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Brand ID', Icons.branding_watermark_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Category & Status'),
                const SizedBox(height: 12),

                // Category Dropdown
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    if (catState is CategoryLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final categories = catState is CategoryLoaded ? catState.categories : context.read<CategoryCubit>().categories;

                    if (categories.isEmpty) {
                      return OutlinedButton.icon(
                        onPressed: () => context.read<CategoryCubit>().loadCategories(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry loading categories'),
                      );
                    }

                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      decoration: _inputDecoration('Category', Icons.category_rounded),
                      hint: const Text('Select a category'),
                      items: categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (val) => setState(() => _selectedCategoryId = val),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Status toggle
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    title: const Text('Product Active', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_status ? 'Visible in the shop' : 'Hidden from customers'),
                    value: _status,
                    activeColor: AppColors.primary,
                    onChanged: _isSubmitting ? null : (val) => setState(() => _status = val),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Submit Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _isEdit ? 'Save Changes' : 'Create Product',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover, width: 160, height: 160);
    }
    if (_isEdit && (widget.existingProduct?.imageUrl.isNotEmpty ?? false)) {
      return Image.network(
        widget.existingProduct!.imageUrl,
        fit: BoxFit.cover,
        width: 160,
        height: 160,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text('Tap to upload', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
