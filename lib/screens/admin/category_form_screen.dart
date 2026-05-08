import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/category/category_cubit.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? existingCategory;
  const CategoryFormScreen({super.key, this.existingCategory});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _status = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameCtrl.text = widget.existingCategory!.name;
      _descCtrl.text = widget.existingCategory!.description ?? '';
      _status = widget.existingCategory!.status;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existingCategory == null) {
      context.read<CategoryCubit>().createCategory(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: _status,
      ).then((_) => context.pop());
    } else {
      context.read<CategoryCubit>().editCategory(
        id: widget.existingCategory!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: _status,
      ).then((_) => context.pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCategory != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Category' : 'Create Category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Is Active (Status)'),
                value: _status,
                onChanged: (val) {
                  setState(() => _status = val);
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Category', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
