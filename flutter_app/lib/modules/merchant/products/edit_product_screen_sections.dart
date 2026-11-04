part of 'edit_product_screen.dart';

extension _EditProductScreenStateSections on _EditProductScreenState {
  Widget _buildImageSlot(int index) {
    final hasImage = _existingImages[index];
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: index < 2 ? AppSpacing.sm : 0),
        child: GestureDetector(
          // Photos already on the product are shown; adding or removing them is not built yet.
          onTap: () => GBSnack.plain('Photos not available yet', 'Photo upload is coming soon. For now, products are saved without photos.', position: SnackPosition.BOTTOM),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color:
                  hasImage ? AppColors.primaryContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasImage ? AppColors.primary : AppColors.border,
                width: hasImage ? 1.5 : 1,
              ),
            ),
            child: hasImage
                ? const Center(
                    child: Icon(Icons.image,
                        color: AppColors.primary, size: 36),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.textHint, size: 28),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Add Photo',
                          style: AppTextStyles.labelSmall),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Update Product'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: (_isDeleting || _isSaving) ? null : _deleteProduct,
                child: _isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error))
                    : Text(
                        'Delete Product',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.error),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: enabled ? onChanged : null,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name']!)))
          .toList(),
    );
  }
}
