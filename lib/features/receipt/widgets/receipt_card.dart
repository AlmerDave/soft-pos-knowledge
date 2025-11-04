import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/app_decorations.dart';
import '../../../config/constants.dart';
import '../../../models/card_details.dart';

class ReceiptCard extends StatelessWidget {
  final double amount;
  final CardDetails? cardDetails;

  const ReceiptCard({
    super.key,
    required this.amount,
    this.cardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final card = cardDetails ?? CardDetails.defaultCard();
    final now = DateTime.now();
    final formattedDate = '${_getMonthName(now.month)} ${now.day}, ${now.year}';
    final formattedTime = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: AppDecorations.receiptCard,
      child: Column(
        children: [
          // Card Type with Real Badge
          _buildReceiptRowWithBadge(
            'Card Type',
            '${card.cardType} ${card.formattedCardNumber}',
            showBadge: card.isRealCard,
          ),
          _buildDivider(),
          _buildReceiptRow('Cardholder', card.cardholderName),
          _buildDivider(),
          _buildReceiptRow('Expiry Date', card.expiryDate),
          _buildDivider(),
          _buildReceiptRow('Date & Time', '$formattedDate $formattedTime'),
          _buildDivider(),
          _buildReceiptRow(
            'Transaction ID',
            '${card.isRealCard ? 'REAL' : 'DEMO'}-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
          ),
          _buildTotalDivider(),
          _buildReceiptRow(
            'Total Amount',
            '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.amountMedium
                : AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRowWithBadge(String label, String value, {bool showBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.nfc,
                        size: 10,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'REAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.border, height: 1);
  }

  Widget _buildTotalDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 2,
      color: AppColors.border,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}