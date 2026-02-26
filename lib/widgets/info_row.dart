import 'package:flutter/material.dart';

/// A widget that displays a label-value pair in a row layout.
/// 
/// The label appears on the left in grey text, and the value appears
/// on the right in black text. When [selectable] is true, the value
/// uses SelectableText to allow copying.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool selectable;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: selectable
                ? SelectableText(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
