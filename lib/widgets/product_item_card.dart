import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/invoice_item.dart';

/// Row displaying a single invoice line item, with edit/delete actions.
class ProductItemCard extends StatelessWidget {
  final InvoiceItem item;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductItemCard({
    super.key,
    required this.item,
    this.currencySymbol = '\$',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × $currencySymbol${item.unitPrice.toStringAsFixed(2)}'
                  '${item.discountPercent > 0 ? '  (-${item.discountPercent.toStringAsFixed(0)}%)' : ''}',
                  style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '$currencySymbol${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.subtitle),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
