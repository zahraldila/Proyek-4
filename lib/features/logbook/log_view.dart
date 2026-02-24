import 'package:flutter/material.dart';
import 'package:logbook_app_094/features/logbook/log_controller.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();

  // Langkah 4: Controller input dialog
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    await _controller.loadFromDisk(widget.username);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingView()),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================
  // Langkah 4: Dialog ADD
  // ==========================
  void _showAddLogDialog() {
    _titleController.clear();
    _contentController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul Catatan"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Isi Deskripsi"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _contentController.text.trim();
              if (title.isEmpty || desc.isEmpty) return;

              await _controller.addLog(widget.username, title, desc);

              _titleController.clear();
              _contentController.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ==========================
  // Langkah 4/5: Dialog EDIT
  // ==========================
  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul Catatan"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Isi Deskripsi"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _contentController.text.trim();
              if (title.isEmpty || desc.isEmpty) return;

              await _controller.updateLog(widget.username, index, title, desc);

              _titleController.clear();
              _contentController.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "LogBook: ${widget.username}",
          style: const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: titleColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),

      // Langkah 4: FAB memanggil add dialog
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // ===== header wavy hijau =====
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

            // konten
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // welcome card
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
                      "$greeting, ${widget.username} 👋",
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

                  // Langkah 5: Edit & Delete di item list
                  Expanded(
                    child: ValueListenableBuilder<List<LogModel>>(
                      valueListenable: _controller.logsNotifier,
                      builder: (context, currentLogs, _) {
                        if (currentLogs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Belum ada catatan.",
                              style: TextStyle(color: bodyColor),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: currentLogs.length,
                          itemBuilder: (context, index) {
                            final log = currentLogs[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: cardWhite.withOpacity(0.92),
                              child: ListTile(
                                leading: const Icon(Icons.note),
                                title: Text(log.title),
                                subtitle: Text(log.description),

                                // Langkah 5: trailing Wrap (Edit & Delete)
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showEditLogDialog(index, log),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await _controller.removeLog(
                                            widget.username, index);
                                        // tanpa setState (ValueNotifier auto refresh)
                                      },
                                    ),
                                  ],
                                ),
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

// wave header
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