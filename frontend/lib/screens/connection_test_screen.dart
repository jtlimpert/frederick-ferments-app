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

  /// Formats supplier address from structured fields.
  String _formatAddress(dynamic supplier) {
    final parts = <String>[];

    if (supplier.streetAddress != null && supplier.streetAddress!.isNotEmpty) {
      parts.add(supplier.streetAddress!);
    }

    final cityStateParts = <String>[];
    if (supplier.city != null && supplier.city!.isNotEmpty) {
      cityStateParts.add(supplier.city!);
    }
    if (supplier.state != null && supplier.state!.isNotEmpty) {
      cityStateParts.add(supplier.state!);
    }
    if (supplier.zipCode != null && supplier.zipCode!.isNotEmpty) {
      cityStateParts.add(supplier.zipCode!);
    }

    if (cityStateParts.isNotEmpty) {
      parts.add(cityStateParts.join(' '));
    }

    if (supplier.country != null && supplier.country!.isNotEmpty) {
      parts.add(supplier.country!);
    }

    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

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

  Future<void> _testSuppliersFetch() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching suppliers...';
    });

    try {
      final service = ref.read(graphqlServiceProvider.notifier);
      final suppliers = await service.getSuppliers();

      if (mounted) {
        setState(() {
          _status = 'Found ${suppliers.length} suppliers:\n\n'
              '${suppliers.map((s) => '${s.name}\n'
                  'Address: ${_formatAddress(s)}\n'
                  'Coords: ${s.hasCoordinates ? "${s.latitude}, ${s.longitude}" : "No coordinates"}').join('\n\n')}';
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _testSuppliersFetch,
                child: const Text('Fetch Suppliers with Coordinates'),
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
