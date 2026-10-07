import 'package:flutter/material.dart';

import '../models/energy_transfer.dart';
import '../models/meter.dart';
import '../services/energy_api_client.dart';
import '../services/transfer_ticket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/meter_card.dart';
import '../widgets/quick_action.dart';
import '../widgets/usage_trend_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.api,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    super.key,
  });

  final EnergyApiClient api;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<Meter> _meters = const [];
  List<EnergyTransfer> _transfers = const [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final state = await widget.api.loadDashboard();
      if (!mounted) return;
      setState(() {
        _meters = state.meters;
        _transfers = state.transfers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _addMeter(Meter meter) async {
    final savedMeter = await widget.api.createMeter(meter);
    if (!mounted) return;
    setState(() => _meters = [..._meters, savedMeter]);
  }

  Future<EnergyTransfer> _recordTransfer({
    required String fromMeterId,
    required String toMeterId,
    required double amountKwh,
  }) async {
    final result = await widget.api.createTransfer(
      fromMeterId: fromMeterId,
      toMeterId: toMeterId,
      amountKwh: amountKwh,
    );
    if (mounted) {
      setState(() {
        final updatedMeters = {
          for (final meter in result.meters) meter.id: meter,
        };
        _meters = _meters
            .map((meter) => updatedMeters[meter.id] ?? meter)
            .toList();
        _transfers = [result.transfer, ..._transfers];
      });
    }
    return result.transfer;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        userName: widget.userName,
        meters: _meters,
        transfers: _transfers,
        onSelectTab: _selectTab,
        onPrintTicket: _printTicket,
      ),
      _MetersTab(
        meters: _meters,
        onSelectTab: _selectTab,
        onAddMeter: _addMeter,
      ),
      _TransferTab(meters: _meters, onTransfer: _recordTransfer),
      const _ConnectTab(),
      _ProfileTab(
        meterCount: _meters.length,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Smart Energy'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _selectTab(3),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _LoadErrorView(
              error: _loadError.toString(),
              onRetry: () => _loadDashboard(showLoading: true),
            )
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.electrical_services_outlined),
            selectedIcon: Icon(Icons.electrical_services_rounded),
            label: 'Meters',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Transfer',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _printTicket(EnergyTransfer transfer) async {
    try {
      await const TransferTicketService().printOrShare(transfer);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create the PDF ticket: $error')),
      );
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.userName,
    required this.meters,
    required this.transfers,
    required this.onSelectTab,
    required this.onPrintTicket,
  });

  final String userName;
  final List<Meter> meters;
  final List<EnergyTransfer> transfers;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<EnergyTransfer> onPrintTicket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          'Welcome, ${userName.split(' ').first}',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here’s your energy at a glance.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        BalanceCard(meters: meters, todayUsageKwh: null),
        const SizedBox(height: 14),
        const UsageTrendCard(),
        const SizedBox(height: 21),
        const _SectionHeading(title: 'Quick actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAction(
                icon: Icons.swap_horiz_rounded,
                label: 'Transfer units',
                color: AppColors.blue,
                onTap: () => onSelectTab(2),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: QuickAction(
                icon: Icons.electrical_services_rounded,
                label: 'My meters',
                color: AppColors.green,
                onTap: () => onSelectTab(1),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: QuickAction(
                icon: Icons.forum_rounded,
                label: 'Connect',
                color: const Color(0xFF8057C7),
                onTap: () => onSelectTab(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeading(title: 'My meters'),
            TextButton(
              onPressed: () => onSelectTab(1),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...meters
            .take(2)
            .map(
              (meter) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MeterCard(meter: meter, showLastUpdated: false),
              ),
            ),
        const SizedBox(height: 23),
        const _SectionHeading(title: 'Recent activity'),
        const SizedBox(height: 12),
        if (transfers.isEmpty)
          const AppCard(
            child: Text(
              'Your meter and transfer records from the Smart database appear here.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          )
        else
          ...transfers
              .take(5)
              .map(
                (transfer) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransferActivityTile(
                    transfer: transfer,
                    onPrintTicket: () => onPrintTicket(transfer),
                  ),
                ),
              ),
        const SizedBox(height: 14),
        const _PrototypeNote(),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TransferActivityTile extends StatelessWidget {
  const _TransferActivityTile({
    required this.transfer,
    required this.onPrintTicket,
  });

  final EnergyTransfer transfer;
  final VoidCallback onPrintTicket;

  @override
  Widget build(BuildContext context) {
    final date = transfer.createdAt.toLocal();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transfer.fromMeterName} to ${transfer.toMeterName}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day}/${date.month}/${date.year} · Database record',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${transfer.formattedAmount} kWh',
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Get PDF ticket',
            onPressed: onPrintTicket,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.muted,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetersTab extends StatelessWidget {
  const _MetersTab({
    required this.meters,
    required this.onSelectTab,
    required this.onAddMeter,
  });

  final List<Meter> meters;
  final ValueChanged<int> onSelectTab;
  final Future<void> Function(Meter) onAddMeter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _PageIntro(
          title: 'My meters',
          subtitle: 'Keep your energy meter records together.',
        ),
        const SizedBox(height: 18),
        ...meters.map(
          (meter) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MeterCard(meter: meter),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final meter = await _showAddMeterDialog(context, meters);
            if (meter != null) {
              try {
                await onAddMeter(meter);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save this meter: $error')),
                );
              }
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add a meter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeading(title: 'Account data'),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.sync_rounded,
          title: 'Smart database records',
          description:
              'Meter balances and transfer history are loaded from your Smart account.',
          accent: AppColors.blue,
          trailing: 'View system status',
          onTap: () => onSelectTab(3),
        ),
        const SizedBox(height: 22),
        const _PrototypeNote(),
      ],
    );
  }
}

class _TransferTab extends StatefulWidget {
  const _TransferTab({required this.meters, required this.onTransfer});

  final List<Meter> meters;
  final Future<EnergyTransfer> Function({
    required String fromMeterId,
    required String toMeterId,
    required double amountKwh,
  })
  onTransfer;

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  final _amountController = TextEditingController();
  late String _fromMeterId;
  late String _toMeterId;
  EnergyTransfer? _lastTransfer;

  @override
  void initState() {
    super.initState();
    _fromMeterId = widget.meters.isEmpty ? '' : widget.meters.first.id;
    _toMeterId = widget.meters.length > 1 ? widget.meters[1].id : _fromMeterId;
  }

  @override
  void didUpdateWidget(covariant _TransferTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.meters.isEmpty) {
      _fromMeterId = '';
      _toMeterId = '';
      return;
    }
    if (!widget.meters.any((meter) => meter.id == _fromMeterId)) {
      _fromMeterId = widget.meters.first.id;
    }
    if (!widget.meters.any((meter) => meter.id == _toMeterId)) {
      _toMeterId = widget.meters.length > 1
          ? widget.meters[1].id
          : widget.meters.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meters.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: const [
          _PageIntro(
            title: 'Transfer units',
            subtitle: 'Record a balance movement between your accounts.',
          ),
          SizedBox(height: 20),
          AppCard(
            child: Text(
              'No meter records are available yet. Add a meter to get started.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      );
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fromMeter = widget.meters.firstWhere(
      (meter) => meter.id == _fromMeterId,
    );
    final toMeter = widget.meters.firstWhere((meter) => meter.id == _toMeterId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _PageIntro(
          title: 'Transfer units',
          subtitle: 'Record a balance movement between your accounts.',
        ),
        if (widget.meters.length < 2) ...[
          const SizedBox(height: 20),
          const AppCard(
            child: Text(
              'Add at least two meter records to prepare a balance movement.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          const _SectionHeading(title: 'From meter'),
          const SizedBox(height: 9),
          _MeterPicker(
            meters: widget.meters,
            value: fromMeter,
            onChanged: (value) => setState(() => _fromMeterId = value.id),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Icon(Icons.south_rounded, color: AppColors.blue, size: 24),
          ),
          const SizedBox(height: 16),
          const _SectionHeading(title: 'To meter'),
          const SizedBox(height: 9),
          _MeterPicker(
            meters: widget.meters,
            value: toMeter,
            onChanged: (value) => setState(() => _toMeterId = value.id),
          ),
          const SizedBox(height: 21),
          const _SectionHeading(title: 'Units to transfer'),
          const SizedBox(height: 9),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              suffixText: 'kWh',
              prefixIcon: Icon(Icons.bolt_rounded),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _EstimateRow(
                  label: '${fromMeter.name} balance after',
                  value:
                      '${(fromMeter.balanceKwh - amount).clamp(0, fromMeter.balanceKwh).toStringAsFixed(1)} kWh',
                ),
                const Divider(height: 20, color: AppColors.border),
                _EstimateRow(
                  label: '${toMeter.name} balance after',
                  value:
                      '${(toMeter.balanceKwh + amount).toStringAsFixed(1)} kWh',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _confirmTransfer,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Review transfer'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          if (_lastTransfer case final transfer?) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _printTicket(context, transfer),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Get PDF ticket'),
            ),
          ],
          const SizedBox(height: 12),
          const _PrototypeNote(),
        ],
      ],
    );
  }

  Future<void> _confirmTransfer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount of units first.')),
      );
      return;
    }
    final fromMeter = widget.meters.firstWhere(
      (meter) => meter.id == _fromMeterId,
    );
    final toMeter = widget.meters.firstWhere((meter) => meter.id == _toMeterId);
    if (fromMeter.id == toMeter.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different meters.')),
      );
      return;
    }
    if (amount > fromMeter.balanceKwh) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The source meter has insufficient units.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm database record'),
        content: Text(
          'Move ${amount.toStringAsFixed(1)} kWh from ${fromMeter.name} '
          'to ${toMeter.name}? This updates balances in the Smart database '
          'only. No utility meter or TANESCO account will be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final transfer = await widget.onTransfer(
        fromMeterId: fromMeter.id,
        toMeterId: toMeter.id,
        amountKwh: amount,
      );
      if (!mounted) return;
      setState(() {
        _lastTransfer = transfer;
        _amountController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transfer record saved to the database. No utility account was changed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the transfer: $error')),
      );
    }
  }

  Future<void> _printTicket(
    BuildContext context,
    EnergyTransfer transfer,
  ) async {
    try {
      await const TransferTicketService().printOrShare(transfer);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create the PDF ticket: $error')),
      );
    }
  }
}

class _MeterPicker extends StatelessWidget {
  const _MeterPicker({
    required this.meters,
    required this.value,
    required this.onChanged,
  });

  final List<Meter> meters;
  final Meter value;
  final ValueChanged<Meter> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Meter>(
      initialValue: value,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.bolt_rounded)),
      items: [
        for (final meter in meters)
          DropdownMenuItem(value: meter, child: Text(meter.transferLabel)),
      ],
      onChanged: (meter) {
        if (meter != null) onChanged(meter);
      },
    );
  }
}

class _ConnectTab extends StatelessWidget {
  const _ConnectTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _PageIntro(
          title: 'System status',
          subtitle: 'A clear view of your account and future integrations.',
        ),
        const SizedBox(height: 18),
        const _SectionHeading(title: 'Available now'),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.save_outlined,
          title: 'Smart database storage',
          description:
              'Your account, meter records, balances, and transfer history are saved in the Smart database.',
          accent: AppColors.green,
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.picture_as_pdf_outlined,
          title: 'PDF transfer tickets',
          description:
              'Create a printable ticket for each transfer record saved to Smart.',
          accent: AppColors.blue,
        ),
        const SizedBox(height: 23),
        const _SectionHeading(title: 'Integration'),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.link_off_rounded,
          title: 'TANESCO connection planned',
          description:
              'Meter verification and real utility transfers will require a future TANESCO API integration.',
          accent: AppColors.amber,
        ),
        const SizedBox(height: 22),
        const _PrototypeNote(),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.meterCount,
    required this.userName,
    required this.userEmail,
  });

  final int meterCount;
  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _PageIntro(
          title: 'Your profile',
          subtitle: 'Manage your account and preferences.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Color(0xFFEAF3FC),
                child: Text(
                  userName
                      .split(' ')
                      .where((part) => part.isNotEmpty)
                      .take(2)
                      .map((part) => part[0].toUpperCase())
                      .join(),
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        const _SectionHeading(title: 'Account'),
        const SizedBox(height: 9),
        _ProfileOption(
          icon: Icons.electrical_services_outlined,
          title: 'Meter records',
          subtitle: '$meterCount database meter records',
          onTap: () => _showPrototypeMessage(context),
        ),
        _ProfileOption(
          icon: Icons.link_off_rounded,
          title: 'Utility integration',
          subtitle: 'Not connected',
          onTap: () => _showPrototypeMessage(context),
        ),
        _ProfileOption(
          icon: Icons.shield_outlined,
          title: 'Security',
          onTap: () => _showPrototypeMessage(context),
        ),
        _ProfileOption(
          icon: Icons.help_outline_rounded,
          title: 'Help and support',
          onTap: () => _showPrototypeMessage(context),
        ),
        const SizedBox(height: 14),
        const _PrototypeNote(),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        trailing!,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppColors.blue),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    );
  }
}

class _PrototypeNote extends StatelessWidget {
  const _PrototypeNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ACCOUNT DATA · Stored in the Smart database',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.muted, fontSize: 10),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.muted,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your account data from Smart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

Future<Meter?> _showAddMeterDialog(BuildContext context, List<Meter> meters) =>
    showDialog<Meter>(
      context: context,
      builder: (context) => _AddMeterDialog(meters: meters),
    );

class _AddMeterDialog extends StatefulWidget {
  const _AddMeterDialog({required this.meters});

  final List<Meter> meters;

  @override
  State<_AddMeterDialog> createState() => _AddMeterDialogState();
}

class _AddMeterDialogState extends State<_AddMeterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  MeterKind _kind = MeterKind.home;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a meter record'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Meter name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Meter number',
                  hintText: 'e.g. 0100 123 456',
                ),
                validator: (value) {
                  final number = value?.trim() ?? '';
                  if (number.isEmpty) return 'Enter a meter number.';
                  if (widget.meters.any((meter) => meter.number == number)) {
                    return 'This meter number is already added.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MeterKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Meter type'),
                items: const [
                  DropdownMenuItem(value: MeterKind.home, child: Text('Home')),
                  DropdownMenuItem(
                    value: MeterKind.business,
                    child: Text('Business'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Starting balance',
                  suffixText: 'kWh',
                ),
                validator: (value) {
                  final balance = double.tryParse(value ?? '');
                  if (balance == null || !balance.isFinite || balance < 0) {
                    return 'Enter zero or more units.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'This meter is stored in Smart only. It is not connected to or verified by a utility.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Meter(
                id: 'meter-${DateTime.now().microsecondsSinceEpoch}',
                name: _nameController.text.trim(),
                number: _numberController.text.trim(),
                balanceKwh: double.parse(_balanceController.text),
                kind: _kind,
                status: MeterStatus.pending,
                lastUpdated: 'just now',
              ),
            );
          },
          child: const Text('Add meter'),
        ),
      ],
    );
  }
}

void _showPrototypeMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This action will be available in a future version.'),
    ),
  );
}
