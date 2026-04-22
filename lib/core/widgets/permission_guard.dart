import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';

/// Renders [child] only if the user has the required permission(s).
/// Shows [fallback] (default: empty SizedBox) otherwise.
///
/// Usage:
/// ```dart
/// // Single permission:
/// PermissionGuard(
///   permission: Perm.opdReceiptCancel,
///   child: CancelButton(),
/// )
///
/// // Any of these:
/// PermissionGuard(
///   anyOf: [Perm.opdReceiptCreate, Perm.opdReceiptRefund],
///   child: BillingActions(),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  /// Require exactly this one permission key.
  final String? permission;

  /// Render child if user has ANY of these keys.
  final List<String>? anyOf;

  /// Render child only if user has ALL of these keys.
  final List<String>? allOf;

  final Widget child;

  /// Widget shown when permission is denied. Defaults to [SizedBox.shrink].
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    this.permission,
    this.anyOf,
    this.allOf,
    required this.child,
    this.fallback,
  }) : assert(
          permission != null || anyOf != null || allOf != null,
          'Provide at least one of: permission, anyOf, or allOf',
        );

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();

    bool granted = false;
    if (permission != null) granted = perm.can(permission!);
    if (anyOf != null)       granted = perm.canAny(anyOf!);
    if (allOf != null)       granted = perm.canAll(allOf!);

    return granted ? child : (fallback ?? const SizedBox.shrink());
  }
}
