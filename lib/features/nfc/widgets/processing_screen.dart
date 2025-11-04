import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/app_decorations.dart';
import '../../../config/constants.dart';
import '../../../core/widgets/info_card.dart';
import '../../../models/card_details.dart';
import '../widgets/log_entry.dart';
import '../../receipt/widgets/success_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final double amount;
  final CardDetails? cardDetails;

  const ProcessingScreen({
    super.key,
    required this.amount,
    this.cardDetails,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final List<Map<String, dynamic>> _logs = [];
  final ScrollController _scrollController = ScrollController();
  late CardDetails _card;

  @override
  void initState() {
    super.initState();
    _card = widget.cardDetails ?? CardDetails.defaultCard();
    _startProcessing();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    final logs = [
      {
        'title': 'NFC Connection Established',
        'description': _card.isRealCard 
            ? 'Secure connection created with physical card'
            : 'Simulated NFC connection created',
        'type': LogType.success,
        'delay': 500,
      },
      {
        'title': 'Card Detected',
        'description': 'Reading card information...',
        'type': LogType.loading,
        'delay': 1000,
      },
      {
        'title': 'Card Identified',
        'description': '${_card.cardType} card detected\nCard: ${_card.formattedCardNumber}',
        'type': LogType.success,
        'delay': 1500,
      },
      {
        'title': 'Reading Card Data',
        'description': 'Expiry: ${_card.expiryDate}\nCardholder: ${_card.cardholderName}',
        'type': LogType.info,
        'delay': 1000,
      },
      {
        'title': 'Validating Card',
        'description': 'Checking card status and limits',
        'type': LogType.loading,
        'delay': 1200,
      },
      {
        'title': 'Card Validated',
        'description': 'Card is active and valid',
        'type': LogType.success,
        'delay': 800,
      },
      {
        'title': 'Generating Cryptogram',
        'description': 'Creating secure transaction code...',
        'type': LogType.loading,
        'delay': 1500,
      },
      {
        'title': 'Cryptogram Generated',
        'description': 'Secure code: ${_generateCryptogram()}',
        'type': LogType.success,
        'delay': 1000,
      },
      {
        'title': 'Contacting Payment Network',
        'description': 'Sending authorization request to ${_card.cardType} network...',
        'type': LogType.loading,
        'delay': 1500,
      },
      {
        'title': 'Bank Processing',
        'description': 'Verifying funds and card status...',
        'type': LogType.info,
        'delay': 1500,
      },
      {
        'title': 'Authorization Approved',
        'description': 'Transaction approved by issuing bank',
        'type': LogType.success,
        'delay': 1000,
      },
      {
        'title': 'Transaction Complete',
        'description': _card.isRealCard
            ? 'Payment successful with real card!'
            : 'Simulated payment successful!',
        'type': LogType.success,
        'delay': 800,
      },
    ];

    for (var log in logs) {
      await Future.delayed(Duration(milliseconds: log['delay'] as int));
      if (mounted) {
        setState(() {
          _logs.add(log);
        });
        _scrollToBottom();
      }
    }

    // Navigate to success screen
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(
            amount: widget.amount,
            cardDetails: _card,
          ),
        ),
      );
    }
  }

  String _generateCryptogram() {
    // Generate a random-looking cryptogram for display
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(12, (i) => chars[(random + i) % chars.length]).join();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          'Processing Payment',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_card.isRealCard) ...[
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
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'REAL',
                                  style: TextStyle(
                                    fontSize: 11,
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
                      _card.isRealCard
                          ? 'Processing real NFC card transaction'
                          : 'Technical process in real-time (Demo)',
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
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Amount Display
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: AppDecorations.borderRadiusLarge,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount',
                              style: AppTextStyles.label,
                            ),
                            Text(
                              '${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}',
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Logs Container
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.logBackground,
                            borderRadius: AppDecorations.borderRadiusLarge,
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return LogEntry(
                                title: log['title'],
                                description: log['description'],
                                type: log['type'],
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InfoCard(
                          title: _card.isRealCard
                              ? '✅ Real Card Detected'
                              : '👁️ Behind the Scenes',
                          description: _card.isRealCard
                              ? 'Processing with actual NFC card data. In real transactions, this happens in 1-2 seconds!'
                              : 'Watch each step of the payment process. In real transactions, this happens in 1-2 seconds!',
                          icon: _card.isRealCard ? Icons.credit_card : Icons.visibility,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}