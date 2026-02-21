import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/logger_service.dart';

/// Global error boundary that catches and handles widget build errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.screenName,
    this.onRetry,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Reset error state when widget is recreated
    _error = null;
    _stackTrace = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context);
    }

    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stackTrace = details.stack;
          });
          LoggerService.error(
            'Error in ${widget.screenName}',
            error: details.exception,
            stackTrace: details.stack,
          );
        }
      });
      return _buildErrorWidget(context);
    };
    
    return widget.child;
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We encountered an unexpected error. Don\'t worry, your data is safe.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha(179),
                      ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode && _error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: Text(
                      _error.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onRetry != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _stackTrace = null;
                          });
                          widget.onRetry?.call();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home-screen',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper for async operations with error handling
class AsyncErrorBoundary extends StatelessWidget {
  final Future<Widget> Function() builder;
  final String screenName;

  const AsyncErrorBoundary({
    super.key,
    required this.builder,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: builder(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          LoggerService.error(
            'Async error in $screenName',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return ErrorBoundary(
            screenName: screenName,
            child: Container(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return snapshot.data ?? Container();
      },
    );
  }
}