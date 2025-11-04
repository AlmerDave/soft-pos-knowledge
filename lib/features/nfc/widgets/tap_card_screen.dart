import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/card_details.dart';
import '../widgets/nfc_animation.dart';
import 'processing_screen.dart';


class TapCardScreen extends StatefulWidget {
  final double amount;

  const TapCardScreen({super.key, required this.amount});

  @override
  State<TapCardScreen> createState() => _TapCardScreenState();
}

class _TapCardScreenState extends State<TapCardScreen>
    with SingleTickerProviderStateMixin {
  
  // Add these constants at the top of your class
  static const SELECT_PPSE = [
    0x00, 0xA4, 0x04, 0x00, // CLA, INS, P1, P2
    0x0E, // Lc (length)
    0x32, 0x50, 0x41, 0x59, 0x2E, 0x53, 0x59, 0x53, 0x2E, 0x44, 0x44, 0x46, 0x30, 0x31, // "2PAY.SYS.DDF01"
    0x00  // Le
  ];

  static const GET_PROCESSING_OPTIONS = [
    0x80, 0xA8, 0x00, 0x00, // CLA, INS, P1, P2
    0x02, // Lc
    0x83, 0x00, // PDOL
    0x00  // Le
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isNfcAvailable = false;
  bool _isCheckingNfc = true;
  bool _isReadingCard = false;
  bool _isReinitializingNfc = false;
  
  // Stored card data
  CardDetails? _storedCardData;
  String? _storedTagId;
  String? _storedHistoricalBytes;
  Map<String, dynamic>? _storedEmvData;
  
  // Debug logs - unlimited
  final List<String> _debugLogs = [];
  final ScrollController _debugScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addDebugLog('🔧 Initializing NFC...');
    _checkNfcAvailability();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _addDebugLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    debugPrint(message);
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_debugScrollController.hasClients) {
        _debugScrollController.animateTo(
          _debugScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (mounted) {
        setState(() {
          _isNfcAvailable = isAvailable;
          _isCheckingNfc = false;
        });
        
        if (isAvailable) {
          _addDebugLog('✅ NFC is available');
          _addDebugLog('👂 Listening for cards...');
          _startNfcSession();
        } else {
          _addDebugLog('❌ NFC not available');
          _showNfcUnavailableDialog();
        }
      }
    } catch (e) {
      _addDebugLog('⚠️ Error: ${e.toString().substring(0, 30)}...');
      if (mounted) {
        setState(() {
          _isNfcAvailable = false;
          _isCheckingNfc = false;
        });
        _showNfcUnavailableDialog();
      }
    }
  }

  void _showNfcUnavailableDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text('NFC Not Available'),
            ],
          ),
          content: const Text(
            'Real NFC card reading is not available on this device or browser.\n\n'
            'You can still simulate the payment process with demo data.\n\n'
            '💡 For real NFC: Use a native mobile app or supported PWA.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    });
  }

  void _startNfcSession() {
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        if (_isReadingCard) return;
        
        _addDebugLog('📡 Card detected!');
        
        setState(() {
          _isReadingCard = true;
        });

        try {
          await _readCardData(tag);
          
          if (mounted) {
            setState(() {
              _isReadingCard = false;
            });
            
            _addDebugLog('✅ Card data saved! Tap "Process Payment" to continue');
            
            _showSnackBar('Card read successfully! Press "Process Payment" button', Colors.green);
          }
        } catch (e) {
          _addDebugLog('❌ Read error: ${e.toString()}');
          if (mounted) {
            setState(() {
              _isReadingCard = false;
            });
            _showErrorSnackBar();
          }
        }
      },
    );
  }

  Future<Map<String, dynamic>> _readEmvData(IsoDepAndroid isoDep) async {
    Map<String, dynamic> emvData = {};
    
    try {
      _addDebugLog('💳 Starting EMV read...');
      
      // Select PPSE (Payment System Environment)
      var response = await isoDep.transceive(Uint8List.fromList(SELECT_PPSE));
      _addDebugLog('📤 SELECT PPSE response: ${_toHex(response)}');
      
      if (response.length >= 2) {
        final sw1 = response[response.length - 2];
        final sw2 = response[response.length - 1];
        
        if (sw1 == 0x90 && sw2 == 0x00) {
          _addDebugLog('✅ PPSE selected successfully');
          
          // Parse PPSE response to get AID (Application ID)
          final aid = _parseAIDFromPPSE(response);
          if (aid != null) {
            _addDebugLog('🆔 AID found: ${_toHex(aid)}');
            emvData['aid'] = _toHex(aid);
            
            // Select application by AID
            final selectAID = [
              0x00, 0xA4, 0x04, 0x00, // SELECT command
              aid.length, // Lc
              ...aid,
              0x00 // Le
            ];
            
            response = await isoDep.transceive(Uint8List.fromList(selectAID));
            _addDebugLog('📤 SELECT AID response: ${_toHex(response)}');
            
            // Get Processing Options
            response = await isoDep.transceive(Uint8List.fromList(GET_PROCESSING_OPTIONS));
            _addDebugLog('📤 GPO response: ${_toHex(response)}');
            
            // Read card data records
            emvData.addAll(await _readCardRecords(isoDep));
          }
        } else {
          _addDebugLog('⚠️ PPSE selection failed: SW=$sw1$sw2');
        }
      }
    } catch (e) {
      _addDebugLog('❌ EMV read error: ${e.toString()}');
    }
    
    return emvData;
  }

  Uint8List? _parseAIDFromPPSE(Uint8List response) {
    try {
      // Simple TLV parsing to find AID (tag 0x4F)
      for (int i = 0; i < response.length - 2; i++) {
        if (response[i] == 0x4F) {
          final length = response[i + 1];
          if (i + 2 + length <= response.length) {
            return response.sublist(i + 2, i + 2 + length);
          }
        }
      }
    } catch (e) {
      _addDebugLog('⚠️ AID parse error: ${e.toString()}');
    }
    return null;
  }

  Future<Map<String, dynamic>> _readCardRecords(IsoDepAndroid isoDep) async {
    Map<String, dynamic> cardData = {};
    
    try {
      // Try multiple SFIs (Short File Identifiers) and records
      // Common SFIs: 1, 2, 3, and records 1-5
      final sfiList = [1, 2, 3];
      final recordList = [1, 2, 3, 4, 5];
      
      for (final sfi in sfiList) {
        for (final record in recordList) {
          try {
            // Calculate P2 byte: (SFI << 3) | 0x04
            final p2 = (sfi << 3) | 0x04;
            
            final readRecord = [
              0x00, 0xB2, record, p2, // READ RECORD
              0x00
            ];
            
            var response = await isoDep.transceive(Uint8List.fromList(readRecord));
            
            // Check status word (SW1 SW2)
            if (response.length >= 2) {
              final sw1 = response[response.length - 2];
              final sw2 = response[response.length - 1];
              
              if (sw1 == 0x90 && sw2 == 0x00) {
                _addDebugLog('✅ READ RECORD SFI=$sfi, REC=$record: ${_toHex(response.sublist(0, response.length - 2))}');
                
                // Remove status word from response
                final data = response.sublist(0, response.length - 2);
                
                // Parse PAN (Primary Account Number) - tag 0x5A
                final pan = _parseTLV(data, 0x5A);
                if (pan != null && !cardData.containsKey('pan')) {
                  cardData['pan'] = _toHex(pan);
                  _addDebugLog('💳 PAN: ${_maskPAN(_toHex(pan))}');
                }
                
                // Parse Cardholder Name - tag 0x5F20
                final cardholderName = _parseTLV(data, 0x5F20);
                if (cardholderName != null && !cardData.containsKey('cardholderName')) {
                  try {
                    cardData['cardholderName'] = utf8.decode(cardholderName).trim();
                    _addDebugLog('👤 Cardholder: ${cardData['cardholderName']}');
                  } catch (_) {}
                }
                
                // Parse Expiry Date - tag 0x5F24
                final expiryDate = _parseTLV(data, 0x5F24);
                if (expiryDate != null && !cardData.containsKey('expiryDate')) {
                  cardData['expiryDate'] = _toHex(expiryDate);
                  _addDebugLog('📅 Expiry: ${_toHex(expiryDate)}');
                }
                
                // Parse Application Label - tag 0x50
                final appLabel = _parseTLV(data, 0x50);
                if (appLabel != null && !cardData.containsKey('appLabel')) {
                  try {
                    cardData['appLabel'] = utf8.decode(appLabel).trim();
                    _addDebugLog('🏷️ App Label: ${cardData['appLabel']}');
                  } catch (_) {}
                }
                
              } else if (sw1 == 0x6A && sw2 == 0x82) {
                // File not found - expected for some SFI/record combinations
                _addDebugLog('ℹ️ SFI=$sfi, REC=$record not found (6A82)');
              } else if (sw1 == 0x6A && sw2 == 0x83) {
                // Record not found
                _addDebugLog('ℹ️ SFI=$sfi, REC=$record empty (6A83)');
                break; // No more records in this SFI
              } else {
                _addDebugLog('⚠️ SFI=$sfi, REC=$record error: $sw1$sw2');
              }
            }
          } catch (e) {
            _addDebugLog('⚠️ SFI=$sfi, REC=$record error: ${e.toString()}');
          }
        }
      }
      
    } catch (e) {
      _addDebugLog('❌ Record read error: ${e.toString()}');
    }
    
    return cardData;
  }

  String _detectCardType(String? aid) {
    if (aid == null) return 'Unknown';
    
    // Visa: A0000000031010
    if (aid.startsWith('A000000003')) {
      return 'Visa';
    }
    // Mastercard: A0000000041010 or A0000000049999
    if (aid.startsWith('A000000004')) {
      return 'Mastercard';
    }
    // American Express: A00000002501
    if (aid.startsWith('A000000025')) {
      return 'American Express';
    }
    // Discover: A0000001523010
    if (aid.startsWith('A000000152')) {
      return 'Discover';
    }
    // JCB: A00000006510
    if (aid.startsWith('A000000065')) {
      return 'JCB';
    }
    // UnionPay: A000000333010101
    if (aid.startsWith('A000000333')) {
      return 'UnionPay';
    }
    
    return 'Unknown';
  }

  String _formatExpiryDate(String hexExpiry) {
    try {
      // EMV expiry format is YYMMDD in hex (e.g., "251231" = Dec 2025)
      if (hexExpiry.length >= 4) {
        final year = hexExpiry.substring(0, 2);
        final month = hexExpiry.substring(2, 4);
        return '$month/$year';
      }
    } catch (e) {
      _addDebugLog('⚠️ Expiry format error: ${e.toString()}');
    }
    return '';
  }

  String _formatPAN(String hexPAN) {
    try {
      // Remove 'F' padding at the end if present
      final pan = hexPAN.replaceAll('F', '');
      
      // Format as groups of 4
      if (pan.length >= 4) {
        return pan.substring(pan.length - 4);
      }
      return pan;
    } catch (e) {
      return hexPAN;
    }
  }

  Uint8List? _parseTLV(Uint8List data, int tag) {
    try {
      for (int i = 0; i < data.length - 2; i++) {
        // Handle single-byte tags
        if (data[i] == tag) {
          int length = data[i + 1];
          int dataStart = i + 2;
          
          // Handle multi-byte length (if length > 127)
          if (length > 0x7F) {
            final numLengthBytes = length & 0x7F;
            length = 0;
            for (int j = 0; j < numLengthBytes; j++) {
              length = (length << 8) | data[i + 2 + j];
            }
            dataStart = i + 2 + numLengthBytes;
          }
          
          if (dataStart + length <= data.length) {
            return data.sublist(dataStart, dataStart + length);
          }
        }
        
        // Handle two-byte tags (like 0x5F20, 0x5F24)
        if (i < data.length - 3 && 
            data[i] == 0x5F && 
            data[i + 1] == (tag & 0xFF)) {
          int length = data[i + 2];
          int dataStart = i + 3;
          
          if (length > 0x7F) {
            final numLengthBytes = length & 0x7F;
            length = 0;
            for (int j = 0; j < numLengthBytes; j++) {
              length = (length << 8) | data[i + 3 + j];
            }
            dataStart = i + 3 + numLengthBytes;
          }
          
          if (dataStart + length <= data.length) {
            return data.sublist(dataStart, dataStart + length);
          }
        }
      }
    } catch (e) {
      _addDebugLog('⚠️ TLV parse error for tag ${tag.toRadixString(16)}: ${e.toString()}');
    }
    return null;
  }

  String _maskPAN(String pan) {
    if (pan.length < 8) return '****';
    return '${pan.substring(0, 4)}****${pan.substring(pan.length - 4)}';
  }

  Future<void> _readCardData(NfcTag tag) async {
    try {
      _addDebugLog('🔍 Reading card data...');

      // Reset stored data
      _storedTagId = null;
      _storedHistoricalBytes = null;
      _storedEmvData = null;

      // --- Extract Tag ID ---
      try {
        dynamic idCandidate = (tag as dynamic).id;

        if (idCandidate != null) {
          final bytes = _toUint8List(idCandidate);
          final hexId = _toHex(bytes);
          final base64Id = base64Encode(bytes);
          
          _storedTagId = hexId;
          
          _addDebugLog('🔑 Tag ID (hex): $hexId');
          _addDebugLog('🔑 Tag ID (base64): $base64Id');
        } else {
          _addDebugLog('🔑 Tag ID not found');
        }
      } catch (e) {
        _addDebugLog('⚠️ Could not read tag ID: ${e.toString()}');
      }

      // --- Extract Historical Bytes and EMV Data (IsoDep only) ---
      try {
        final isoDep = IsoDepAndroid.from(tag);
        if (isoDep != null) {
          _addDebugLog('💳 Payment card (IsoDep) detected');
          
          // Historical bytes
          try {
            if ((isoDep as dynamic).historicalBytes != null) {
              final hist = _toUint8List((isoDep as dynamic).historicalBytes);
              final hexHist = _toHex(hist);
              
              _storedHistoricalBytes = hexHist;
              
              _addDebugLog('📜 Historical bytes (hex): $hexHist');
            } else {
              _addDebugLog('📜 No historical bytes available');
            }
          } catch (e) {
            _addDebugLog('⚠️ Could not read historical bytes: ${e.toString()}');
          }
          
          // Read EMV data
          final emvData = await _readEmvData(isoDep);
          if (emvData.isNotEmpty) {
            _storedEmvData = emvData;
            _addDebugLog('✅ EMV data extracted successfully');
            
            // Create CardDetails from EMV data
            _storedCardData = _createCardDetailsFromEmv(emvData);
          } else {
            _addDebugLog('ℹ️ No EMV data found, using default');
            _storedCardData = CardDetails.defaultCard();
          }
        } else {
          // Not a payment card
          _addDebugLog('ℹ️ Not a payment card, using default');
          _storedCardData = CardDetails.defaultCard();
        }
      } catch (e) {
        _addDebugLog('⚠️ IsoDep check error: ${e.toString()}');
        _storedCardData = CardDetails.defaultCard();
      }

      // Fallback if no card details created
      _storedCardData ??= CardDetails.defaultCard();
      
      _addDebugLog('💾 Card data stored successfully');
      
    } catch (e) {
      _addDebugLog('❌ Error: ${e.toString()}');
      _storedCardData = CardDetails.defaultCard();
      throw e;
    }
  }

  CardDetails _createCardDetailsFromEmv(Map<String, dynamic> emvData) {
    // Extract PAN (card number)
    String? cardNumber;
    if (emvData.containsKey('pan')) {
      cardNumber = _formatPAN(emvData['pan']);
      _addDebugLog('✅ Using real PAN');
    }
    
    // Extract Expiry Date
    String? expiryDate;
    if (emvData.containsKey('expiryDate')) {
      expiryDate = _formatExpiryDate(emvData['expiryDate']);
      _addDebugLog('✅ Using real expiry date');
    }
    
    // Extract Cardholder Name
    String? cardholderName;
    if (emvData.containsKey('cardholderName')) {
      cardholderName = emvData['cardholderName'];
      _addDebugLog('✅ Using real cardholder name');
    }
    
    // Detect Card Type from AID
    String cardType = 'Unknown';
    if (emvData.containsKey('aid')) {
      cardType = _detectCardType(emvData['aid']);
      _addDebugLog('✅ Card type detected: $cardType');
    }
    
    // Check if we have enough real data
    bool hasRealData = cardNumber != null || expiryDate != null || cardholderName != null;
    
    if (hasRealData) {
      _addDebugLog('🎉 Creating CardDetails with real EMV data');
      return CardDetails.fromNfc(
        cardNumber: cardNumber ?? '•••• 4567',
        expiryDate: expiryDate ?? '12/27',
        cardholderName: cardholderName ?? 'JUAN DELA CRUZ (Default)',
        cardType: cardType,
      );
    } else {
      _addDebugLog('ℹ️ Insufficient EMV data, using default');
      return CardDetails.defaultCard();
    }
  }

  // ---------------------- Helper utilities ----------------------

  Uint8List _toUint8List(dynamic maybeBytes) {
    if (maybeBytes == null) return Uint8List(0);
    if (maybeBytes is Uint8List) return maybeBytes;
    if (maybeBytes is List<int>) return Uint8List.fromList(maybeBytes);
    if (maybeBytes is String) return Uint8List.fromList(utf8.encode(maybeBytes));
    // Sometimes plugins return a base64 string
    try {
      return base64Decode(maybeBytes as String);
    } catch (_) {}
    return Uint8List(0);
  }

  String _toHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString().toUpperCase();
  }

  void _showSnackBar(String message, MaterialColor color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not read card. Please try again.'),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _processPayment() {
    if (_storedCardData == null) {
      // Use demo data if no card was scanned
      _addDebugLog('🎭 Using demo data...');
      _storedCardData = CardDetails.defaultCard();
    } else {
      _addDebugLog('💳 Processing payment with stored card data...');
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          amount: widget.amount,
          cardDetails: _storedCardData!,
        ),
      ),
    ).then((_) {
      // Reset after returning from ProcessingScreen
      if (mounted) {
        setState(() {
          _storedCardData = null;
          _storedTagId = null;
          _storedHistoricalBytes = null;
        });
        _addDebugLog('🔄 Ready for next transaction');
      }
    });
  }

  void _reinitializeNfc() async {
    if (!_isNfcAvailable) {
      _showSnackBar('NFC is not available on this device', Colors.orange);
      return;
    }

    setState(() {
      _isReinitializingNfc = true;
    });

    _addDebugLog('🔄 Reinitializing NFC...');

    try {
      // Stop current session
      await NfcManager.instance.stopSession();
      _addDebugLog('⏸️ NFC session stopped');
      
      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Restart session
      _startNfcSession();
      _addDebugLog('✅ NFC session restarted');
      _addDebugLog('👂 Listening for cards...');
      
      _showSnackBar('NFC reinitialized successfully', Colors.green);
    } catch (e) {
      _addDebugLog('❌ Reinitialize error: ${e.toString()}');
      _showSnackBar('Failed to reinitialize NFC', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isReinitializingNfc = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _debugScrollController.dispose();
    if (_isNfcAvailable) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Ready to Accept Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCheckingNfc || _isReinitializingNfc)
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                  ),
                                ),
                              if (_isCheckingNfc || _isReinitializingNfc) const SizedBox(width: 8),
                              Text(
                                _isCheckingNfc
                                    ? 'Checking NFC...'
                                    : _isReinitializingNfc
                                        ? 'Reinitializing NFC...'
                                        : _isNfcAvailable
                                            ? _isReadingCard
                                                ? 'Reading card...'
                                                : _storedCardData != null
                                                    ? 'Card data ready!'
                                                    : 'Waiting for card...'
                                            : 'NFC not available',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _storedCardData != null
                                      ? Colors.greenAccent
                                      : _isNfcAvailable
                                          ? Colors.white70
                                          : Colors.orange[200],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!_isNfcAvailable && !_isCheckingNfc) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.orange[200],
                                ),
                              ],
                              if (_storedCardData != null) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.greenAccent,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        // Amount Display Card
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryPurple.withOpacity(0.1),
                                      AppColors.primaryPurple.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryPurple.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          color: AppColors.primaryPurple.withOpacity(0.7),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Amount to Pay',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}',
                                      style: AppTextStyles.display1.copyWith(
                                        color: AppColors.primaryPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // NFC Animation with Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const NfcAnimation(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Debug Console - Scrollable and Unlimited
                        Container(
                          width: double.infinity,
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.terminal,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Debug Console',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_debugLogs.length} logs',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _debugLogs.isEmpty
                                    ? Text(
                                        'Waiting for activity...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontFamily: 'monospace',
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _debugScrollController,
                                        itemCount: _debugLogs.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              _debugLogs[index],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.greenAccent,
                                                fontFamily: 'monospace',
                                                height: 1.3,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Instruction with Icon
                        Column(
                          children: [
                            Text(
                              _storedCardData != null
                                  ? 'Card Ready!'
                                  : _isNfcAvailable
                                      ? 'Tap Your Card'
                                      : 'NFC Unavailable',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _storedCardData != null
                                    ? Colors.green.withOpacity(0.1)
                                    : _isNfcAvailable 
                                        ? Colors.amber.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _storedCardData != null
                                      ? Colors.green.withOpacity(0.3)
                                      : _isNfcAvailable
                                          ? Colors.amber.withOpacity(0.3)
                                          : Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _storedCardData != null
                                        ? Icons.check_circle
                                        : _isNfcAvailable
                                            ? Icons.credit_card
                                            : Icons.phonelink_off,
                                    size: 20,
                                    color: _storedCardData != null
                                        ? Colors.green[700]
                                        : _isNfcAvailable 
                                            ? const Color(0xFFF57C00)
                                            : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _storedCardData != null
                                          ? 'Tap "Process Payment" to continue'
                                          : _isNfcAvailable
                                              ? 'Hold your card near the device'
                                              : 'Use simulate button for demo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _storedCardData != null
                                            ? Colors.green[900]
                                            : _isNfcAvailable
                                                ? Colors.amber[900]
                                                : Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info Cards Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.flash_on,
                                title: 'Fast',
                                description: 'Instant payment',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFeatureCard(
                                icon: Icons.security,
                                title: 'Secure',
                                description: 'Encrypted data',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        CustomButton(
                          text: _storedCardData != null ? 'Process Payment' : 'Simulate Payment',
                          onPressed: _processPayment,
                          icon: _storedCardData != null ? Icons.payment : Icons.touch_app,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Reinitialize NFC Button
                        if (_isNfcAvailable)
                          CustomButton(
                            text: _isReinitializingNfc ? 'Reinitializing...' : 'Reinitialize NFC', 
                            onPressed: _isReinitializingNfc ? () {} : _reinitializeNfc,
                            icon: Icons.refresh,
                            isPrimary: false,
                          ),
                        
                        if (_isNfcAvailable) const SizedBox(height: 12),
                        
                        CustomButton(
                          text: 'Cancel Payment',
                          onPressed: () => Navigator.pop(context),
                          isPrimary: false,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Help Text
                        Text(
                          _storedCardData != null
                              ? 'Card data stored. Ready to process payment.'
                              : _isNfcAvailable
                                  ? 'Tap card to read data, then process payment'
                                  : 'Download mobile app for real NFC support',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final textColor = color is MaterialColor 
        ? color[700] ?? color 
        : Color.fromARGB(
            255,
            (color.red * 0.7).round(),
            (color.green * 0.7).round(),
            (color.blue * 0.7).round(),
          );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}