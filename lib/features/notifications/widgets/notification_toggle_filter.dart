import 'package:flutter/material.dart';

class NotificationToggleFilter extends StatefulWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  const NotificationToggleFilter({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  State<NotificationToggleFilter> createState() => _NotificationToggleFilterState();
}

class _NotificationToggleFilterState extends State<NotificationToggleFilter> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: widget.subtitle != null
            ? Text(
                widget.subtitle!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
        value: widget.value,
        onChanged: widget.onChanged,
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }
}