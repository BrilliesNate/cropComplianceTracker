import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Admin diagnostics console for the Farmable Partner API v2.0.
/// Runs every GET endpoint and shows status / count / raw JSON, so we can
/// confirm which endpoints are live (Farmable had `causes` + `treatments`
/// returning 500). The two POST (write) endpoints are listed for reference —
/// they are exercised by the Spray Records submission feature, not from here.
class FarmableConsoleScreen extends StatefulWidget {
  const FarmableConsoleScreen({Key? key}) : super(key: key);

  @override
  State<FarmableConsoleScreen> createState() => _FarmableConsoleScreenState();
}

class _Endpoint {
  final String label;
  final String path;
  final Map<String, String>? query;
  const _Endpoint(this.label, this.path, [this.query]);
}

class _FarmableConsoleScreenState extends State<FarmableConsoleScreen> {
  final _service = FarmableService();

  // 13 list-returning GET endpoints (job-weather handled separately since it
  // needs a jobId).
  static const _getEndpoints = <_Endpoint>[
    _Endpoint('Farms', '/v1/farms'),
    _Endpoint('Fields', '/v1/fields'),
    _Endpoint('Sales', '/v1/sales'),
    _Endpoint('Farm members', '/v1/farm-members'),
    _Endpoint('Teams', '/v1/teams'),
    _Endpoint('Team members', '/v1/team-members'),
    _Endpoint('Timesheets', '/v1/timesheets'),
    _Endpoint('Equipment', '/v1/equipments'),
    _Endpoint('Crops', '/v1/crops'),
    _Endpoint('Crop varieties', '/v1/crop-varieties'),
    _Endpoint('Justifications', '/v1/justifications'),
    _Endpoint('Causes', '/v1/causes'),
    _Endpoint('Treatments', '/v1/treatments'),
  ];

  final Map<String, FarmableRawResult?> _results = {};
  final Set<String> _running = {};
  bool _runningAll = false;

  final _jobIdCtrl = TextEditingController();

  @override
  void dispose() {
    _jobIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(_Endpoint ep) async {
    setState(() => _running.add(ep.path));
    final res = await _service.debugGet(ep.path, ep.query);
    if (!mounted) return;
    setState(() {
      _results[ep.path] = res;
      _running.remove(ep.path);
    });
  }

  Future<void> _runAll() async {
    setState(() => _runningAll = true);
    // Sequential to respect the 60/min rate limit on sales/job endpoints.
    for (final ep in _getEndpoints) {
      await _run(ep);
    }
    if (mounted) setState(() => _runningAll = false);
  }

  Future<void> _runJobWeather() async {
    final id = _jobIdCtrl.text.trim();
    if (id.isEmpty) return;
    const path = '/v1/job-weather';
    setState(() => _running.add(path));
    final res = await _service.debugGet(path, {'jobId': id});
    if (!mounted) return;
    setState(() {
      _results[path] = res;
      _running.remove(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) {
      return const AppScaffoldWrapper(
        title: 'Access Denied',
        child: Center(child: Text('Only administrators can access this.')),
      );
    }

    return AppScaffoldWrapper(
      title: '🌱 Farmable API Console',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 16),
            ..._getEndpoints.map(_endpointCard),
            const SizedBox(height: 8),
            _jobWeatherCard(),
            const SizedBox(height: 20),
            _postSection(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Partner API v2.0 · api.farmable.tech',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              FilledButton.icon(
                onPressed: _runningAll ? null : _runAll,
                icon: _runningAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(_runningAll ? 'Running…' : 'Run all GET'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Read-only probe of every GET endpoint. Runs sequentially to respect '
            'the 60/min rate limit. Empty [] just means no data on the linked '
            'farm; 500 means the endpoint is erroring on Farmable’s side.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _endpointCard(_Endpoint ep) {
    final res = _results[ep.path];
    final busy = _running.contains(ep.path);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _methodChip('GET'),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ep.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(ep.path,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (res != null) _statusBadge(res),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: busy ? null : () => _run(ep),
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Run'),
                ),
              ],
            ),
            if (res != null) _resultBody(res),
          ],
        ),
      ),
    );
  }

  Widget _jobWeatherCard() {
    const path = '/v1/job-weather';
    final res = _results[path];
    final busy = _running.contains(path);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _methodChip('GET'),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Job weather',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$path?jobId=…',
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (res != null) _statusBadge(res),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _jobIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'jobId',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: busy ? null : _runJobWeather,
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Run'),
                ),
              ],
            ),
            if (res != null) _resultBody(res),
          ],
        ),
      ),
    );
  }

  Widget _postSection() {
    Widget postCard(String label, String path, String note) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _methodChip('POST'),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(path,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(note,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Write endpoints',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        postCard('Create spray job', '/v1/spray-jobs',
            'Submitted from the Spray Records feature. Needs causes + treatments (currently 500).'),
        postCard('Create fertilizer job', '/v1/fertilize-jobs',
            'Submitted from the Spray Records feature. Needs treatments (currently 500).'),
      ],
    );
  }

  Widget _methodChip(String m) {
    final color = m == 'GET' ? Colors.blue.shade700 : Colors.deepOrange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(m,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _statusBadge(FarmableRawResult res) {
    final Color color;
    if (res.ok) {
      color = Colors.green.shade700;
    } else if (res.status == -1) {
      color = Colors.grey.shade700;
    } else {
      color = Colors.red.shade700;
    }
    final label = res.status == -1 ? 'ERR' : '${res.status}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        res.count != null ? '$label · ${res.count}' : label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _resultBody(FarmableRawResult res) {
    final preview =
        res.body.length > 4000 ? '${res.body.substring(0, 4000)}\n…(truncated)' : res.body;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (res.rateRemaining != null)
                Text('rate-remaining: ${res.rateRemaining}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: res.body));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Response copied'),
                        duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                preview,
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFFD4D4D4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
