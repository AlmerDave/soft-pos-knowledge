import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../models/card_details.dart';
import '../widgets/receipt_card.dart';
import '../widgets/success_animation.dart';
import '../../home/screens/amount_input_screen.dart';

class SuccessScreen extends StatelessWidget {
  final double amount;
  final CardDetails? cardDetails;

  const SuccessScreen({
    super.key,
    required this.amount,
    this.cardDetails,
  });

  @override
  Widget build(BuildContext context) {
    final card = cardDetails ?? CardDetails.defaultCard();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Payment Complete',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.isRealCard) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.greenAccent,
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.nfc,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'REAL CARD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      card.isRealCard
                          ? 'Real NFC transaction successful'
                          : 'Demo transaction successful',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        
                        // Success Animation
                        const SuccessAnimation(),
                        
                        const SizedBox(height: 30),
                        
                        // Success Title
                        const Text(
                          'Payment Approved!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Success Subtitle
                        Text(
                          card.isRealCard
                              ? 'Your transaction with real card is complete'
                              : 'Your demonstration transaction is complete',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Receipt Card
                        ReceiptCard(
                          amount: amount,
                          cardDetails: card,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // New Transaction Button
                        CustomButton(
                          text: 'New Transaction',
                          onPressed: () {
                            // Navigate back to home and remove all previous routes
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AmountInputScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: Icons.refresh,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        CustomButton(
                          text: 'Share Receipt',
                          onPressed: () {
                            _showShareDialog(context, card);
                          },
                          isPrimary: false,
                          icon: Icons.share,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Info Card
                        InfoCard(
                          title: card.isRealCard
                              ? '✅ Real NFC Card Used'
                              : '🎓 What You Learned',
                          description: card.isRealCard
                              ? 'This transaction used real NFC card data! In production, this would be processed through actual payment networks and settled with banks.'
                              : 'You just saw how Soft POS reads card data, generates secure cryptograms, and communicates with payment networks - all using just a smartphone!',
                          icon: card.isRealCard ? Icons.verified : Icons.school,
                        ),
                        
                        if (card.isRealCard) ...[
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No actual charge was made. This is a demonstration app.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[900],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, CardDetails card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.share, color: AppColors.primaryPurple),
            SizedBox(width: 12),
            Text('Share Receipt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'In a real application, this would allow you to share the receipt via SMS, email, or social media.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Preview:',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${card.cardType} ${card.formattedCardNumber}\n'
                    'Amount: \$${amount.toStringAsFixed(2)}\n'
                    '${card.isRealCard ? '✅ Real Card' : '🎭 Demo'}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a demo app, so sharing is not implemented.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}