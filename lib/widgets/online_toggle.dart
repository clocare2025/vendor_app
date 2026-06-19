import 'package:flutter/material.dart';
import '../providers/status_provider.dart';

class OnlineToggle extends StatelessWidget {
  final StatusProvider statusPvd;
  final String token;

  const OnlineToggle({super.key, required this.statusPvd, required this.token});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: statusPvd.loading ? null : () => statusPvd.toggle(token),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: statusPvd.isOnline
              ? const Color(0xFF16A34A)
              : Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusPvd.isOnline
                ? const Color(0xFF16A34A)
                : Colors.white.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusPvd.loading)
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 1.5),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusPvd.isOnline ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              statusPvd.isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
