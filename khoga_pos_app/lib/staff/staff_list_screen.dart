import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../auth/auth_controller.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBrownDark = Color(0xFF4B382A);
const Color cBrownLight = Color(0xFFE7D1B7);
const Color cBorderLight = Color(0xFFEBEBEB);
const Color cTextMuted = Color(0xFF909090);
const Color cActiveBg = Color(0xFFE8F5E9);
const Color cActiveText = Color(0xFF2E7D32);
const Color cInactiveBg = Color(0xFFFFEBEE);
const Color cInactiveText = Color(0xFFC62828);

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  late final ScheduleApi _api;
  
  List<StaffRoster> _allStaff = [];
  bool _loading = true;
  String? _error;
  String _filterRole = 'ALL';

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.roster();
      if (mounted) {
        setState(() {
          _allStaff = list;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được danh sách nhân viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StaffRoster> get _filteredStaff {
    if (_filterRole == 'ALL') return _allStaff;
    return _allStaff.where((s) => s.role == _filterRole).toList();
  }

  int get _countTotal => _allStaff.length;
  int get _countCashier => _allStaff.where((s) => s.role == 'CASHIER').length;
  int get _countBarista => _allStaff.where((s) => s.role == 'BARISTA').length;
  int get _countManager => _allStaff.where((s) => s.role == 'STORE_MANAGER').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        leadingWidth: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cBrownDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nhân Viên',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                context.watch<AuthController>().profile?.storeName ?? 'Nguyễn Du',
                style: const TextStyle(color: cBrownDark, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Segoe UI'),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, color: cBorderLight),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: cBrownDark)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: cInactiveText, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: cInactiveText, fontFamily: 'Segoe UI')),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: cBrownDark, foregroundColor: Colors.white),
                        child: const Text('Thử lại', style: TextStyle(fontFamily: 'Segoe UI')),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Stats Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox('Tổng NV', _countTotal),
                    const SizedBox(width: 8),
                    _buildStatBox('Cashier', _countCashier),
                    const SizedBox(width: 8),
                    _buildStatBox('Barista', _countBarista),
                    const SizedBox(width: 8),
                    _buildStatBox('Manager', _countManager),
                  ],
                ),
              ),

              // Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'ALL'),
                      _buildFilterChip('Cashier', 'CASHIER'),
                      _buildFilterChip('Barista', 'BARISTA'),
                      _buildFilterChip('Manager', 'STORE_MANAGER'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filteredStaff.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildStaffCard(_filteredStaff[i]),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, int count) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: cBgWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cBorderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cBrownDark, fontFamily: 'Segoe UI'),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: cBrownDark, fontWeight: FontWeight.w600, fontFamily: 'Segoe UI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String role) {
    final isActive = _filterRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _filterRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? cBrownDark : cBgWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? cBrownDark : cBorderLight),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : cBrownDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Segoe UI',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffRoster staff) {
    final names = staff.fullName.trim().split(' ').where((s) => s.isNotEmpty).toList();
    String initials = '';
    if (names.isNotEmpty) {
      initials = names.first[0].toUpperCase();
      if (names.length > 1) {
        initials += names.last[0].toUpperCase();
      }
    }

    final isCashier = staff.role == 'CASHIER';
    final isManager = staff.role == 'STORE_MANAGER';
    
    final avatarBg = isCashier ? cBrownLight : cBrownDark;
    final avatarFg = isCashier ? cBrownDark : Colors.white;

    final roleLabel = isManager ? 'Store Manager' : (isCashier ? 'Cashier' : 'Barista');
    
    final statusBg = staff.isActive ? cActiveBg : cInactiveBg;
    final statusFg = staff.isActive ? cActiveText : cInactiveText;
    final statusText = staff.isActive ? 'Hoạt động' : 'Vô hiệu hóa';

    final authProfile = context.read<AuthController>().profile;
    final isMe = authProfile != null && authProfile.id == staff.userId;

    return Container(
      decoration: BoxDecoration(
        color: cBgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarBg,
            child: Text(
              initials,
              style: TextStyle(color: avatarFg, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Segoe UI'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        staff.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cBrownDark, fontFamily: 'Segoe UI'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusFg, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Segoe UI'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(color: isManager ? cBrownLight : cBrownDark, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Segoe UI'),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      staff.phone ?? 'Chưa cập nhật SĐT',
                      style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'),
                    ),
                    if (isMe)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('BẠN', style: TextStyle(color: cTextMuted, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Segoe UI')),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cActiveText.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.phone, size: 16, color: cActiveText),
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

