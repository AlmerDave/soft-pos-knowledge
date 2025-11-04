import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

enum LogType { loading, success, info, error }

class LogEntry extends StatelessWidget {
  final String title;
  final String? description;
  final LogType type;

  const LogEntry({
    super.key,
    required this.title,
    this.description,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getIconColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _getIcon(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.logText,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.logText.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor() {
    switch (type) {
      case LogType.loading:
        return AppColors.logLoading;
      case LogType.success:
        return AppColors.logSuccess;
      case LogType.info:
        return AppColors.logInfo;
      case LogType.error:
        return AppColors.error;
    }
  }

  Widget _getIcon() {
    switch (type) {
      case LogType.loading:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case LogType.success:
        return const Icon(
          Icons.check,
          color: Colors.white,
          size: 14,
        );
      case LogType.info:
        return const Icon(
          Icons.info_outline,
          color: Colors.white,
          size: 14,
        );
      case LogType.error:
        return const Icon(
          Icons.close,
          color: Colors.white,
          size: 14,
        );
    }
  }
}