
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:travel_planner/database_helper.dart';
import 'package:travel_planner/models/itinerary_item.dart';
import 'package:travel_planner/models/trip.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Trip? _trip;
  List<ItineraryItem> _itineraryItems = [];
  bool _isLoading = true;

  // --- Theme Colors ---
  final Color _backgroundColor = const Color(0xFF2D2F41);
  final Color _cardColor = const Color(0xFF35374B);
  final Color _textColor = Colors.white;
  final Color _hintColor = Colors.white70;
  final Color _accentColor = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    final trip = await _dbHelper.getOrCreateCurrentTrip();
    final items = await _dbHelper.getItineraryItems(trip.id!);
    setState(() {
      _trip = trip;
      _itineraryItems = items;
      _isLoading = false;
    });
  }

  Future<void> _updateTrip() async {
    if (_trip != null) {
      await _dbHelper.updateTrip(_trip!);
    }
  }

  // --- Country Picker ---
  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        backgroundColor: _cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: '국가 검색',
          hintText: '검색할 국가를 입력하세요',
          prefixIcon: Icon(Icons.search, color: _hintColor),
          labelStyle: TextStyle(color: _hintColor),
          hintStyle: TextStyle(color: _hintColor),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _hintColor.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentColor)),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _trip?.destination = country.name;
        });
        _updateTrip();
      },
    );
  }

  // --- Date Picker ---
  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_trip?.startDate ?? DateTime.now()) : (_trip?.endDate ?? _trip?.startDate ?? DateTime.now()),
      firstDate: isStart ? DateTime(2020) : (_trip?.startDate ?? DateTime(2020)),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: _accentColor, onPrimary: Colors.white, surface: _cardColor, onSurface: _textColor),
          dialogBackgroundColor: _backgroundColor,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _trip?.startDate = picked;
          if (_trip?.endDate != null && _trip!.endDate!.isBefore(_trip!.startDate!)) {
            _trip?.endDate = null;
          }
        } else {
          _trip?.endDate = picked;
        }
      });
      _updateTrip();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return DateFormat('yyyy. MM. dd').format(date);
  }

  // --- Itinerary CRUD ---
  void _showItineraryDialog({ItineraryItem? item}) {
    final _textController = TextEditingController(text: item?.content);
    bool isEditing = item != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Text(isEditing ? '일정 수정' : '일정 추가', style: TextStyle(color: _textColor)),
        content: TextField(
          controller: _textController,
          autofocus: true,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            hintText: '일정 내용을 입력하세요',
            hintStyle: TextStyle(color: _hintColor),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _hintColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: TextStyle(color: _hintColor))),
          ElevatedButton(
            onPressed: () async {
              if (_textController.text.isNotEmpty) {
                if (isEditing) {
                  item.content = _textController.text;
                  await _dbHelper.updateItineraryItem(item);
                } else {
                  final newItem = ItineraryItem(
                    tripId: _trip!.id!,
                    content: _textController.text,
                    order: _itineraryItems.length,
                  );
                  await _dbHelper.insertItineraryItem(newItem);
                }
                Navigator.pop(context);
                _loadTripData(); // Reload to get new item with ID
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _deleteItineraryItem(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('삭제 확인', style: TextStyle(color: _textColor)),
        content: Text('이 항목을 정말 삭제하시겠습니까?', style: TextStyle(color: _hintColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: TextStyle(color: _hintColor))),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteItineraryItem(id);
              Navigator.pop(context);
              _loadTripData();
            },
            child: Text('삭제', style: TextStyle(color: _accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _accentColor)),
      );
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('여행 관리', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        foregroundColor: _textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: [
          _buildLocationSection(),
          const SizedBox(height: 12),
          _buildDatesSection(),
          const SizedBox(height: 12),
          _buildItinerarySection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... build methods for sections (Location, Dates, Itinerary) remain largely the same, but use _trip data ...

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: _textColor)),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('여행지'),
        Card(
          color: _cardColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: GestureDetector(
            onTap: _openCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(color: const Color(0xFF232533), borderRadius: BorderRadius.circular(12.0)),
              child: Row(
                children: [
                  Icon(Icons.public, color: _hintColor, size: 20),
                  const SizedBox(width: 12.0),
                  _trip?.destination == null || _trip!.destination!.isEmpty
                      ? Text('어디로 여행가시나요?', style: TextStyle(color: _hintColor, fontSize: 15))
                      : Text(_trip!.destination!, style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: _hintColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('여행 기간'),
        Card(
          color: _cardColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: _buildDateButton(isStart: true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(Icons.arrow_forward, color: _hintColor, size: 20),
                ),
                Expanded(child: _buildDateButton(isStart: false)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({required bool isStart}) {
    DateTime? date = isStart ? _trip?.startDate : _trip?.endDate;
    return GestureDetector(
      onTap: () => _selectDate(context, isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        decoration: BoxDecoration(color: const Color(0xFF232533), borderRadius: BorderRadius.circular(10.0)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _hintColor, size: 18),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  color: date == null ? _hintColor : _textColor,
                  fontSize: 14,
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('여행 일정'),
        Card(
          color: _cardColor,
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
            child: Column(
              children: [
                if (_itineraryItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: Text('아직 추가된 일정이 없습니다.', style: TextStyle(color: _hintColor))),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: _itineraryItems.length,
                      itemBuilder: (context, index) {
                        final item = _itineraryItems[index];
                        return ListTile(
                          key: ValueKey(item.id),
                          contentPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: Colors.white70),
                          ),
                          title: Text(item.content, style: TextStyle(color: _textColor)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: Icon(Icons.edit, color: _hintColor, size: 20), onPressed: () => _showItineraryDialog(item: item)),
                              IconButton(icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20), onPressed: () => _deleteItineraryItem(item.id!)),
                            ],
                          ),
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) async {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final ItineraryItem item = _itineraryItems.removeAt(oldIndex);
                          _itineraryItems.insert(newIndex, item);
                        });
                        await _dbHelper.updateItineraryOrder(_itineraryItems);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showItineraryDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('일정 추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
