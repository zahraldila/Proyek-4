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

  final List<String> _categories = const [
    "Mechanical",
    "Electronic",
    "Software",
  ];

  late String _selectedCategory;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = _categories.contains(widget.log?.category)
        ? widget.log!.category
        : "Mechanical";
    _isPublic = widget.log?.isPublic ?? false;

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
          _isPublic,
        );
      } else {
        await widget.controller.updateLog(
          widget.currentUser['uid'],
          widget.currentUser['role'],
          widget.index!,
          title,
          desc,
          _selectedCategory,
          _isPublic,
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

  Color _categoryColor(String category) {
    switch (category) {
      case "Mechanical":
        return Colors.green;
      case "Electronic":
        return Colors.blue;
      case "Software":
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case "Mechanical":
        return Icons.precision_manufacturing_rounded;
      case "Electronic":
        return Icons.memory_rounded;
      case "Software":
        return Icons.code_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: _categoryColor(_selectedCategory).withOpacity(0.7),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    final accent = _categoryColor(_selectedCategory);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _categoryIcon(_selectedCategory),
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.log == null ? "Catatan Baru" : "Edit Catatan",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2A44),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic
                      ? "Catatan dapat dilihat oleh anggota tim"
                      : "Catatan bersifat private dan hanya Anda yang dapat melihatnya",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFF4A5A7A).withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        final color = _categoryColor(category);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: category == _categories.last ? 0 : 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color.withOpacity(0.55)
                        : Colors.black.withOpacity(0.08),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: isSelected ? color : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : const Color(0xFF4A5A7A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _buildTopSummaryCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kategori",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A44),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _isPublic
                        ? Colors.blue.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (_isPublic ? Colors.blue : Colors.grey)
                          .withOpacity(0.18),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    title: const Text(
                      "Publikasikan ke tim",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _isPublic
                          ? "Catatan bisa dilihat anggota tim lain"
                          : "Catatan hanya bisa dilihat oleh Anda",
                    ),
                    value: _isPublic,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() => _isPublic = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    label: "Judul",
                    hint: "Masukkan judul catatan",
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 320,
                  child: TextField(
                    controller: _descController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: _inputDecoration(
                      label: "Isi Catatan",
                      hint: "Tulis catatan dengan format Markdown...",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Container(
      color: const Color(0xFFF6F8FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            _buildTopSummaryCard(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _descController.text.trim().isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          "Belum ada isi catatan untuk dipratinjau.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A5A7A),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_titleController.text.trim().isNotEmpty) ...[
                          Text(
                            _titleController.text.trim(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F2A44),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        MarkdownBody(
                          data: _descController.text,
                          selectable: true,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
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
          toolbarHeight: 58,
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: titleColor,
          elevation: 0,
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: _categoryColor(_selectedCategory),
            labelColor: titleColor,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(
                text: "Editor",
              ),
              Tab(
                text: "Pratinjau",
              ),
            ],
          ),
          actions: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8CC152).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.save_rounded,
                  color: Color(0xFF8CC152),
                  size: 22,
                ),
                onPressed: _save,
                tooltip: "Simpan",
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildEditorTab(),
            _buildPreviewTab(),
          ],
        ),
      ),
    );
  }
}