import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:logbook_app_094/features/logbook/log_controller.dart';
import 'package:logbook_app_094/features/logbook/log_editor_page.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';
import 'package:logbook_app_094/services/mongo_service.dart';
import 'package:logbook_app_094/services/access_policy.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isOffline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final offlineNow = results.contains(ConnectivityResult.none);
      if (mounted) setState(() => _isOffline = offlineNow);
    });

    _controller.startBackgroundSync(widget.currentUser['teamId']);

    Future.microtask(() => _initDatabase());
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _searchController.dispose();
    _queryNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    if (mounted) setState(() => _isLoading = true);

    const source = "log_view.dart";

    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: source,
        level: 3,
      );

      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: source,
        level: 3,
      );

      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          "Koneksi Cloud Timeout. Periksa sinyal / IP Whitelist (0.0.0.0/0).",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: source,
        level: 2,
      );

      await LogHelper.writeLog(
        "UI: Memanggil controller.loadLogs(teamId)...",
        source: source,
        level: 3,
      );

      await _controller.loadLogs(widget.currentUser['teamId']);

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "UI: Error - SocketException (offline)",
        source: source,
        level: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kamu sedang offline. Cek koneksi internet ya."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (e) {
      await LogHelper.writeLog(
        "UI: Error - TimeoutException ($e)",
        source: source,
        level: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Koneksi timeout. Coba lagi atau cek jaringan/whitelist."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: source,
        level: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masalah: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFromCloud() async {
    const source = "log_view.dart";

    try {
      await LogHelper.writeLog(
        "UI: Pull-to-refresh dipanggil",
        source: source,
        level: 3,
      );

      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("timeout"),
      );

      await _controller.loadLogs(widget.currentUser['teamId']);
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline: tidak bisa refresh dari cloud."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Refresh timeout. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal refresh: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String _formatLogTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return "baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
    if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";

    return DateFormat("d MMM yyyy", "id_ID").format(local);
  }

  Color _categoryAccent(String category) {
    switch (category) {
      case "Pekerjaan":
        return Colors.blue;
      case "Urgent":
        return Colors.red;
      case "Pribadi":
      default:
        return Colors.orange;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case "Pekerjaan":
        return Icons.work_rounded;
      case "Urgent":
        return Icons.warning_rounded;
      case "Pribadi":
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildEmptyState({
    required bool isSearching,
    required bool canCreate,
  }) {
    const bodyColor = Color(0xFF4A5A7A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.auto_stories_rounded,
              size: 100,
              color: bodyColor.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? "Tidak ada catatan yang cocok" : "Belum ada catatan",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? "Coba gunakan kata kunci lain ya 🔎"
                  : "Tekan tombol + untuk menambah catatan pertamamu ✍️",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bodyColor.withOpacity(0.85),
                height: 1.3,
              ),
            ),
            if (!isSearching && canCreate) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _goToEditor(),
                child: const Text("Buat Catatan Pertama"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.98),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [green1, green2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.logout_rounded, color: titleColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Konfirmasi Logout",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin keluar?",
          style: TextStyle(
            color: bodyColor.withOpacity(0.95),
            height: 1.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingView()),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int realIndex, LogModel log) async {
    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.98),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [green1, green2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: titleColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Hapus Catatan?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        content: Text(
          "Yakin mau hapus catatan \"${log.title}\"?\nTindakan ini tidak bisa dibatalkan.",
          style: TextStyle(color: bodyColor.withOpacity(0.95), height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              try {
                if (mounted) setState(() => _isLoading = true);
                await _controller.removeLog(
                  widget.currentUser['uid'],
                  widget.currentUser['role'],
                  realIndex,
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              "Ya, Hapus",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F8FF);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);
    const cardWhite = Color(0xFFFFFFFF);

    final greeting = _getGreeting();
    final String currentRole = widget.currentUser['role'] ?? 'Anggota';

    final bool canCreate = AccessPolicy.canCreate(
      currentUserRole: currentRole,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "LogBook: ${widget.currentUser['username']}",
          style: const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: titleColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(widget.currentUser['teamId']),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _goToEditor(),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [green1, green2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardWhite.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      "$greeting, ${widget.currentUser['username']} 👋",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Catatan",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari berdasarkan judul...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ValueListenableBuilder<String>(
                        valueListenable: _queryNotifier,
                        builder: (context, q, _) {
                          if (q.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _queryNotifier.value = '';
                            },
                          );
                        },
                      ),
                      filled: true,
                      fillColor: cardWhite.withOpacity(0.92),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (text) =>
                        _queryNotifier.value = text.trim().toLowerCase(),
                  ),
                  const SizedBox(height: 10),
                  if (_isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.withOpacity(0.35)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Offline Mode: data mungkin tidak terbaru.",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _queryNotifier,
                      builder: (context, query, _) {
                        return ValueListenableBuilder<List<LogModel>>(
                          valueListenable: _controller.logsNotifier,
                          builder: (context, currentLogs, _) {
                            if (_isLoading) {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text("Menghubungkan ke MongoDB Atlas..."),
                                  ],
                                ),
                              );
                            }

                            final filteredLogs = query.isEmpty
                                ? currentLogs
                                : currentLogs
                                    .where(
                                      (log) =>
                                          log.title.toLowerCase().contains(query),
                                    )
                                    .toList();

                            if (filteredLogs.isEmpty) {
                              return _buildEmptyState(
                                isSearching: query.isNotEmpty,
                                canCreate: canCreate,
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: _refreshFromCloud,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredLogs.length,
                                itemBuilder: (context, index) {
                                  final log = filteredLogs[index];
                                  final realIndex = currentLogs.indexOf(log);
                                  final accent = _categoryAccent(log.category);

                                  final bool canUpdate = AccessPolicy.canEdit(
                                    currentUserId: widget.currentUser['uid'],
                                    currentUserRole: widget.currentUser['role'],
                                    authorId: log.authorId,
                                  );

                                  final bool canDelete = AccessPolicy.canDelete(
                                    currentUserId: widget.currentUser['uid'],
                                    currentUserRole: widget.currentUser['role'],
                                    authorId: log.authorId,
                                  );

                                  return Dismissible(
                                    key: ValueKey(
                                      "$realIndex-${log.title}-${log.category}",
                                    ),
                                    direction: canDelete
                                        ? DismissDirection.endToStart
                                        : DismissDirection.none,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      alignment: Alignment.centerRight,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      if (canDelete) {
                                        await _confirmDelete(realIndex, log);
                                      }
                                      return false;
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      color: cardWhite,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minVerticalPadding: 12,
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _categoryIcon(log.category),
                                            color: accent,
                                          ),
                                        ),
                                        title: Text(
                                          log.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: titleColor,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: bodyColor.withOpacity(0.95),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Kategori: ${log.category}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Waktu: ${_formatLogTime(log.createdAt)}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  log.isSynced
                                                      ? Icons.cloud_done
                                                      : Icons.cloud_off,
                                                  size: 16,
                                                  color: log.isSynced
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  log.isSynced
                                                      ? "Sudah sinkron ke cloud"
                                                      : "Masih tersimpan lokal",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: log.isSynced
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (canUpdate)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () => _goToEditor(
                                                  log: log,
                                                  index: realIndex,
                                                ),
                                              ),
                                            if (canDelete)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _confirmDelete(realIndex, log),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 58);

    path.cubicTo(
      size.width * 0.22,
      size.height + 18,
      size.width * 0.65,
      size.height - 120,
      size.width,
      size.height - 58,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}