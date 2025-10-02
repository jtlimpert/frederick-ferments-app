import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/graphql_service.dart';

/// Screen for testing GraphQL API connectivity.
///
/// Provides buttons to test ping, health check,
/// and inventory fetch operations.
class ConnectionTestScreen extends ConsumerStatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  ConsumerState<ConnectionTestScreen> createState() =>
      _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends ConsumerState<ConnectionTestScreen> {
  String _status = 'Not tested yet';
  bool _isLoading = false;

  Future<void> _testPing() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.ping();
      
      if (mounted) {
        setState(() {
          _status = 'Success! Server responded: $result';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking health...';
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final result = await service.healthCheck();
      
      if (mounted) {
        setState(() {
          _status = 'Health Check:\n'
              'Status: ${result['status']}\n'
              'Database: ${result['databaseConnected']}\n'
              'Version: ${result['version']}\n'
              'Uptime: ${result['uptimeSeconds']}s';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testInventoryFetch() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching inventory...';
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final items = await service.getInventoryItems();
      
      if (mounted) {
        setState(() {
          _status = 'Found ${items.length} inventory items:\n'
              '${items.map((i) => i.name).join(', ')}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Frederick Ferments - Connection Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Test GraphQL Connection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _testPing,
                child: const Text('Test Ping'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _testHealthCheck,
                child: const Text('Test Health Check'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _testInventoryFetch,
                child: const Text('Fetch Inventory Items'),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
