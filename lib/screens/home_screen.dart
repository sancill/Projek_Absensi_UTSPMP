import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/journal_model.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/view_state.dart';
import '../theme/app_theme.dart';
import 'user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  void initState() {
    super.initState();
    // Aturan Emas P05: Panggil startListening() di addPostFrameCallback
    // pada initState untuk menghindari konflik notifyListeners saat proses build tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<JournalProvider>(context, listen: false).startListening();
      }
    });
  }

  @override
  void dispose() {

    super.dispose();
  }

  /// Dialog reusable untuk Tambah & Edit Jurnal (Prinsip DRY sesuai P05/P06)
  void _showJournalDialog({JournalModel? journal, String? prefilledNim}) {
    final isEditing = journal != null;
    final nimController = TextEditingController(
      text: journal?.nim ?? prefilledNim ?? '',
    );
    final noteController = TextEditingController(text: journal?.note ?? '');
    String selectedStatus = journal?.status ?? 'Hadir';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Edit Jurnal Absensi' : 'Catat Absensi Baru',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input NIM Mahasiswa
                  TextFormField(
                    controller: nimController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'NIM Mahasiswa',
                      hintText: 'Contoh: 20115001 atau 2411500011',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.people_alt_outlined, color: AppTheme.primaryColor),
                        tooltip: 'Pilih dari API Mahasiswa',
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final selected = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserListScreen(isPickerMode: true),
                            ),
                          );
                          if (selected != null) {
                            _showJournalDialog(prefilledNim: selected);
                          }
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'NIM wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Pilihan Status Kehadiran
                  const Text(
                    'Status Kehadiran:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Hadir', 'Sakit', 'Izin', 'Alpa'].map((status) {
                      final isSelected =
                          selectedStatus.toUpperCase() == status.toUpperCase();
                      return ChoiceChip(
                        label: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: _getStatusColor(status),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedStatus = status;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Catatan / Keterangan
                  TextFormField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Keterangan',
                      hintText: 'Misal: Mengikuti perkuliahan dengan baik.',
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Keterangan absensi wajib diisi';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final provider = Provider.of<JournalProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final nim = nimController.text.trim();
                final note = noteController.text.trim();

                Navigator.pop(ctx);

                try {
                  if (isEditing) {
                    await provider.updateJournal(
                      id: journal.id,
                      nim: nim,
                      status: selectedStatus,
                      note: note,
                    );
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Jurnal berhasil diperbarui')),
                      );
                    }
                  } else {
                    await provider.addJournal(
                      nim: nim,
                      status: selectedStatus,
                      note: note,
                    );
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Jurnal berhasil ditambahkan')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Operasi gagal: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Perbarui' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return AppTheme.hadirText;
      case 'SAKIT':
        return AppTheme.sakitText;
      case 'IZIN':
        return AppTheme.izinText;
      case 'ALPA':
        return AppTheme.alpaText;
      default:
        return AppTheme.primaryColor;
    }
  }

  /// Dialog Konfirmasi Hapus Data
  void _confirmDelete(JournalModel journal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jurnal?'),
        content: Text('Apakah Anda yakin ingin menghapus data absensi untuk NIM ${journal.nim}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final provider = Provider.of<JournalProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await provider.deleteJournal(journal.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Data absensi berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Jurnal Absensi'),
        actions: [
          // Tombol Navigasi ke List API (Mahasiswa Reqres)
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Daftar Mahasiswa (API)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListScreen()),
              );
            },
          ),
          
          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Summary Banner Statistik
              _buildStatsBanner(provider),

              // Search & Filter Bar
              _buildFilterBar(provider),

              // Konten Utama berdasarkan ViewState
              Expanded(
                child: _buildBodyContent(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJournalDialog(),
        tooltip: 'Catat Absensi',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildStatsBanner(JournalProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', provider.totalCount.toString(), AppTheme.primaryColor),
          _statItem('Hadir', provider.hadirCount.toString(), AppTheme.hadirText),
          _statItem('Sakit', provider.sakitCount.toString(), AppTheme.sakitText),
          _statItem('Izin', provider.izinCount.toString(), AppTheme.izinText),
          _statItem('Alpa', provider.alpaCount.toString(), AppTheme.alpaText),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(JournalProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        children: [
          // TextField Pencarian

          const SizedBox(height: 8),

          // Chips Filter Status (Semua, Hadir, Sakit, Izin, Alpa)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Hadir', 'Sakit', 'Izin', 'Alpa'].map((filter) {
                final isSelected = provider.statusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                    showCheckmark: false,
                    onSelected: (_) => provider.setStatusFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(JournalProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Memuat jurnal absensi realtime...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );

      case ViewState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Terjadi kendala data:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refreshOnce(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );

      case ViewState.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Belum ada catatan absensi.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tekan tombol + di bawah untuk mencatat absensi baru.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        );

      case ViewState.loaded:
        final list = provider.filteredJournals;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada data yang cocok dengan filter.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final journal = list[index];
            return _buildJournalCard(journal);
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Kartu Jurnal Absensi PERSIS sesuai referensi UI (pmpl_003-005/salah satu referensi UI.png)
  Widget _buildJournalCard(JournalModel journal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: NIM di kiri & Status Capsule Badge di kanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NIM: ${journal.nim}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: journal.badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    journal.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: journal.badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Baris 2: Tanggal & Waktu format '2 Nov 2026, 10:30'
            Text(
              journal.formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),

            // Baris 3: Teks Catatan / Keterangan
            Text(
              journal.note,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),

            // Baris 4: Aksi Edit & Hapus (Kanan Bawah)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                  tooltip: 'Edit Jurnal',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showJournalDialog(journal: journal),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade600),
                  tooltip: 'Hapus Jurnal',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(journal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
