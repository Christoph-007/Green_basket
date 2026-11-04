part of 'product_detail_screen.dart';

extension _ProductDetailScreenSections on ProductDetailScreen {
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryText),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, 
              style: isBold ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium),
          Text(value, 
              style: isBold ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
