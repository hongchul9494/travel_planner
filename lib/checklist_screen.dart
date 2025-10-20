
import 'package:flutter/material.dart';
import 'package:travel_planner/database_helper.dart';
import 'package:travel_planner/models/checklist_item.dart';

// --- Main Screen Widget ---
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late Future<List<ChecklistItem>> _itemsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _textFieldController = TextEditingController();

  // --- Theme Colors (Consistent with TripScreen) ---
  final Color _backgroundColor = const Color(0xFF2D2F41);
  final Color _cardColor = const Color(0xFF35374B);
  final Color _textColor = Colors.white;
  final Color _hintColor = Colors.white70;
  final Color _accentColor = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = _dbHelper.getItems();
    });
  }

  // --- Dialog for Adding/Editing Items ---
  Future<void> _showItemDialog({ChecklistItem? item}) async {
    _textFieldController.text = item?.name ?? '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(item == null ? '준비물 추가' : '준비물 수정', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _textFieldController,
            autofocus: true,
            style: TextStyle(color: _textColor),
            decoration: InputDecoration(
              hintText: '예: 여권, 충전기...',
              hintStyle: TextStyle(color: _hintColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _hintColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
            ),
            onSubmitted: (_) => _handleSave(item: item),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(color: _hintColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('저장'),
              onPressed: () => _handleSave(item: item),
            ),
          ],
        );
      },
    );
  }

  // --- Confirmation Dialog for Deleting ---
  Future<void> _showDeleteConfirmationDialog(ChecklistItem item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: Text('삭제 확인', style: TextStyle(color: _textColor)),
          content: Text("'${item.name}' 항목을 삭제하시겠습니까?", style: TextStyle(color: _hintColor)),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(color: _hintColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _accentColor),
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(item);
              },
            ),
          ],
        );
      },
    );
  }

  // --- Handle Save/Update/Delete ---
  void _handleSave({ChecklistItem? item}) async {
    final String name = _textFieldController.text;
    if (name.isNotEmpty) {
      if (item == null) {
        await _dbHelper.insertItem(ChecklistItem(name: name));
      } else {
        item.name = name;
        await _dbHelper.updateItem(item);
      }
      _refreshItems();
      Navigator.of(context).pop();
    }
  }
  
  void _handleToggle(ChecklistItem item) async {
      item.isChecked = !item.isChecked;
      await _dbHelper.updateItem(item);
      _refreshItems();
  }
  
  void _handleDelete(ChecklistItem item) async {
      if (item.id != null) {
          await _dbHelper.deleteItem(item.id!); 
          _refreshItems();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${item.name}' 항목이 삭제되었습니다."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
      }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, 
      appBar: AppBar(
        title: const Text('준비물 체크리스트', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _backgroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<ChecklistItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _accentColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildItemCard(item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        tooltip: '준비물 추가',
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 80, color: _hintColor),
          const SizedBox(height: 16),
          Text(
            '체크리스트가 비어있습니다.',
            style: TextStyle(fontSize: 18, color: _hintColor),
          ),
          Text(
            "'+' 버튼을 눌러 준비물을 추가하세요!",
            style: TextStyle(fontSize: 16, color: _hintColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // --- Themed Item Card ---
  Widget _buildItemCard(ChecklistItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        onTap: () => _showItemDialog(item: item), // Tap to edit
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (bool? value) => _handleToggle(item),
          activeColor: _accentColor,
          checkColor: Colors.white,
          side: BorderSide(color: _hintColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 17,
            color: item.isChecked ? _hintColor : _textColor,
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            decorationColor: _hintColor,
            decorationThickness: 2.0,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22),
          onPressed: () => _showDeleteConfirmationDialog(item),
          tooltip: '삭제',
        ),
      ),
    );
  }
}
