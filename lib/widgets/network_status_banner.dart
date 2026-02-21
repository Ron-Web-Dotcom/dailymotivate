import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/connectivity_service.dart';

/// Network status banner widget
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      initialData: ConnectivityService().isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
            color: Colors.orange.shade700,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                SizedBox(width: 2.w),
                Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
