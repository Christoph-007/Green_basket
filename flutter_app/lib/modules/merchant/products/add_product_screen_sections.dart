part of 'add_product_screen.dart';

extension _AddProductScreenStateSections on _AddProductScreenState {
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: List.generate(4, (i) {
          final isCompleted = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  i == 0
                      ? 'Basic'
                      : i == 1
                          ? 'Price'
                          : i == 2
                              ? 'Images'
                              : 'Prep',
                  style: AppTextStyles.labelSmall.copyWith(
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs),
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: index < 2 ? AppSpacing.sm : 0),
        child: GestureDetector(
          // Photo upload is not built yet; say so instead of pretending a photo was added.
          onTap: () => GBSnack.plain('Photos not available yet', 'Photo upload is coming soon. For now, products are saved without photos.', position: SnackPosition.BOTTOM),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.textHint, size: 28),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  index == 0 ? 'Main Photo' : 'Photo ${index + 1}',
                  style: AppTextStyles.labelSmall,
                ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: GBButton(label: 'Back', onPressed: _prevStep, variant: GBButtonVariant.outline),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: GBButton(label: _currentStep < 3 ? 'Next Step' : 'Add Product', isLoading: _isSubmitting, onPressed: (_currentStep < 3 ? _nextStep : _submitProduct)),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
    );
  }
}
