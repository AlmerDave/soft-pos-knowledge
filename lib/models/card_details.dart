class CardDetails {
  final String cardNumber;
  final String expiryDate;
  final String cardholderName;
  final String cardType;
  final bool isRealCard;

  CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardholderName,
    required this.cardType,
    this.isRealCard = false,
  });

  // Default static card for simulation
  factory CardDetails.defaultCard() {
    return CardDetails(
      cardNumber: '•••• 4567',
      expiryDate: '12/27',
      cardholderName: 'JUAN DELA CRUZ (Default)',
      cardType: 'Visa',
      isRealCard: false,
    );
  }

  // Create from NFC data
  factory CardDetails.fromNfc({
    required String cardNumber,
    required String expiryDate,
    String? cardholderName,
    required String cardType,
  }) {
    return CardDetails(
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      cardholderName: cardholderName ?? 'CARDHOLDER',
      cardType: cardType,
      isRealCard: true,
    );
  }

  // Format card number (show last 4 digits)
  String get formattedCardNumber {
    if (cardNumber.length >= 4) {
      final lastFour = cardNumber.substring(cardNumber.length - 4);
      return '•••• $lastFour';
    }
    return cardNumber;
  }
}