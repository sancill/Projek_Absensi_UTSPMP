import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/data_provider.dart';
import '../providers/view_state.dart';
import '../theme/app_theme.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  final bool isPickerMode;

  const UserListScreen({super.key, this.isPickerMode = false});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {

  @override
  void initState() {
    super.initState();
    // Memuat data dari REST API Reqres via Dio (Spesifikasi P02 & P03)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<DataProvider>(context, listen: false);
        if (provider.users.isEmpty) {
          provider.loadUsers();
        }
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.isPickerMode ? 'Pilih Mahasiswa' : 'Daftar Mahasiswa (API)'),

      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, _) {
          return Column(
            children: [


              // Content based on ViewState
              Expanded(
                child: _buildBody(dataProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(DataProvider provider) {
    switch (provider.state) {
      case ViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Mengambil data mahasiswa via Dio...',
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
                const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Gagal Mengambil Data API',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.loadUsers(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi (Retry)'),
                ),
              ],
            ),
          ),
        );

      case ViewState.empty:
        return const Center(
          child: Text('Tidak ada data pengguna yang ditemukan.'),
        );

      case ViewState.loaded:
        final filteredUsers = provider.users;

        return RefreshIndicator(
          onRefresh: () => provider.refreshUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserCard(user);
            },
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: NetworkImage(user.avatar),
          onBackgroundImageError: (exception, stackTrace) {},
          child: user.avatar.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'NIM: ${user.simulatedNim}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: widget.isPickerMode
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.pop(context, user.simulatedNim);
                },
                child: const Text('Pilih'),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          if (widget.isPickerMode) {
            Navigator.pop(context, user.simulatedNim);
          } else {
            // Navigasi ke Layar ke-4: Detail API (Spesifikasi Layar 4)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserDetailScreen(user: user),
              ),
            );
          }
        },
      ),
    );
  }
}
