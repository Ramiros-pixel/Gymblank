import 'package:flutter/material.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
import 'package:gym_slot/providers/integration_provider.dart';
import 'package:provider/provider.dart';

/// Layar pendaftaran gym baru (Phase 2).
/// Hanya dapat diakses oleh user dengan role owner.
class RegisterGymScreen extends StatefulWidget {
  const RegisterGymScreen({super.key});

  @override
  State<RegisterGymScreen> createState() => _RegisterGymScreenState();
}

class _RegisterGymScreenState extends State<RegisterGymScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gymNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'Asia/Jakarta');

  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _gymNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final gymProvider = context.read<GymProvider>();

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final gym = await gymProvider.createGym(
        gymName: _gymNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        timezone: _timezoneController.text.trim().isEmpty
            ? null
            : _timezoneController.text.trim(),
      );

      if (gym != null) {
        setState(() {
          _success = 'Gym "${gym.gymName}" berhasil dibuat.';
          _isLoading = false;
        });
        // Tunggu sebentar lalu navigasi ke layar koneksi Google Drive
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GoogleDriveConnectScreen(
                  gymId: gym.gymId,
                  ownerUserId: auth.user?.userId ?? '',
                ),
              ),
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal membuat gym. Coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Gym Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pendaftaran Gym',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Isi data gym Anda. Anda akan menjadi Owner gym ini.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _gymNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Gym',
                hintText: 'Contoh: Fitness Center Jakarta',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama gym wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Contoh: Jl. Sudirman No. 1, Jakarta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Contoh: 08123456789',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Kontak',
                hintText: 'contoh@email.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timezoneController,
              decoration: const InputDecoration(
                labelText: 'Zona Waktu',
                hintText: 'Asia/Jakarta',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.green.shade50,
                child: Text(
                  _success!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Daftar Gym'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar koneksi Google Drive/Sheets (Phase 2).
/// Owner mengotorisasi akses Drive lalu spreadsheet gym dibuat.
class GoogleDriveConnectScreen extends StatefulWidget {
  final String gymId;
  final String ownerUserId;

  const GoogleDriveConnectScreen({
    super.key,
    required this.gymId,
    required this.ownerUserId,
  });

  @override
  State<GoogleDriveConnectScreen> createState() =>
      _GoogleDriveConnectScreenState();
}

class _GoogleDriveConnectScreenState extends State<GoogleDriveConnectScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _status;
  String? _authUrl;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final integration = context.read<IntegrationProvider>();
    await integration.loadStatus();
    setState(() {
      _status = integration.connectionStatus;
      _error = integration.error;
      _isLoading = false;
    });
  }

  Future<void> _startConnect() async {
    final integration = context.read<IntegrationProvider>();
    await integration.startConnect(ownerUserId: widget.ownerUserId);
    setState(() {
      _authUrl = integration.authorizationUrl;
      _error = integration.error;
      _status = integration.connectionStatus;
    });
  }

  Future<void> _createSpreadsheet() async {
    final integration = context.read<IntegrationProvider>();
    await integration.createSpreadsheet(
      gymId: widget.gymId,
      ownerUserId: widget.ownerUserId,
    );
    setState(() {
      _status = integration.connectionStatus;
      _error = integration.error;
    });
  }

  Future<void> _disconnect() async {
    final integration = context.read<IntegrationProvider>();
    await integration.disconnect();
    setState(() {
      _status = integration.connectionStatus;
      _error = integration.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = _status?['connected'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Google Drive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  'Koneksi Google Drive',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                  const SizedBox(height: 8),
                  Text(
                    'Izinkan GymSlot mengakses Google Drive Anda untuk membuat spreadsheet booking gym.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Status kartu
                  Card(
                    child: ListTile(
                      leading: Icon(
                        connected ? Icons.cloud_done : Icons.cloud_off,
                        color: connected ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        connected ? 'Terhubung' : 'Belum Terhubung',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _status?['status'] ?? '-',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.shade50,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!connected) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _startConnect,
                        icon: const Icon(Icons.login),
                        label: const Text('Mulai Autorisasi Google Drive'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_authUrl != null) ...[
                      Text(
                        'Buka URL berikut di browser:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _authUrl!,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Setelah memberikan izin, salin kode autorisasi yang muncul dan masukkan di bawah.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Kode Autorisasi',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submitAuthCode(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitAuthCode,
                          child: const Text('Simpan Kode Autorisasi'),
                        ),
                      ),
                    ],
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Putuskan Koneksi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _createSpreadsheet,
                        icon: const Icon(Icons.create),
                        label: const Text('Buat Spreadsheet GymBooking'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    'Langkah selanjutnya:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Koneksikan Google Drive\n'
                    '2. Buat spreadsheet GymBooking\n'
                    '3. Gym siap digunakan untuk booking',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  void _submitAuthCode() {
    // TODO: Implement auth code input with state handling
    // Untuk MVP, flow callback otomatis via doGet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gunakan tombol "Mulai Autorisasi" dan ikuti alur browser.'),
      ),
    );
  }
}
