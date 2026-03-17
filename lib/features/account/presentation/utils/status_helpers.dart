import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/data/models/auth_models.dart';

/// Get status text based on user status
String getStatusText(UserStatus status, AppLocalizations? l10n) {
  switch (status) {
    case UserStatus.pending:
      return l10n?.pendingReview ?? 'Pending review';
    case UserStatus.rejected:
      return l10n?.rejected ?? 'Rejected';
    case UserStatus.needMoreInfo:
      return l10n?.needMoreInfo ?? 'Need more information';
    default:
      return l10n?.pendingReview ?? 'Pending';
  }
}

/// Get status color based on user status
Color getStatusColor(UserStatus status) {
  switch (status) {
    case UserStatus.pending:
      return Colors.orange;
    case UserStatus.rejected:
      return Colors.red;
    case UserStatus.needMoreInfo:
      return Colors.blue;
    default:
      return Colors.grey;
  }
}
