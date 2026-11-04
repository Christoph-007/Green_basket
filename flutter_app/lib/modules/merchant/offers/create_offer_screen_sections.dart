part of 'create_offer_screen.dart';

extension _CreateOfferScreenStateSections on _CreateOfferScreenState {
  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDatePicker(
      String label, DateTime? date, VoidCallback onTap) {
    return Semantics(button: true, child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: GBCard.decoration().copyWith(border: Border.all(
            color: date != null ? AppColors.primary : AppColors.border,
          )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: date != null
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
