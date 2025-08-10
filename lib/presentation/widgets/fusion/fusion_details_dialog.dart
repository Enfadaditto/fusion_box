import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details.dart';

class FusionDetailsDialog extends StatefulWidget {
  final Fusion fusion;

  const FusionDetailsDialog({
    super.key,
    required this.fusion,
  });

  static void show(BuildContext context, Fusion fusion) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FusionDetailsDialog(fusion: fusion),
    );
  }

  @override
  State<FusionDetailsDialog> createState() => _FusionDetailsDialogState();
}

class _FusionDetailsDialogState extends State<FusionDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: null,
      contentPadding: const EdgeInsets.all(24),
      content: FusionDetailsContent(fusion: widget.fusion),
    );
  }
} 