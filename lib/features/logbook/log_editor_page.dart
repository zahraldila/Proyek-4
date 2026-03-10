import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:logbook_app_094/features/logbook/log_controller.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  final List<String> _categories = const ["Pekerjaan", "Pribadi", "Urgent"];
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? "Pribadi";

    _descController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul dan isi catatan tidak boleh kosong."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (widget.log == null) {
        await widget.controller.addLog(
          title,
          desc,
          _selectedCategory,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
        );
      } else {
        await widget.controller.updateLog(
          widget.currentUser['uid'],
          widget.currentUser['role'],
          widget.index!,
          title,
          desc,
          _selectedCategory,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.log == null
                  ? "Catatan berhasil disimpan"
                  : "Catatan berhasil diperbarui",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan catatan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF1F2A44);
    const bgColor = Color(0xFFF6F8FF);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: titleColor,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCategory = value);
                    },
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Judul",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: "Tulis catatan dengan format Markdown...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: _descController.text.trim().isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada isi catatan untuk dipratinjau.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      child: MarkdownBody(
                        data: _descController.text,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}