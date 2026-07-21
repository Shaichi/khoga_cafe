import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

/// Screen 47 — View Branch Staff List (UC-66). Manager scope.
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  late final ScheduleApi _api;
  final _searchController = TextEditingController();
  
  List<StaffRoster> _allStaff = const [];
  List<StaffRoster> _filteredStaff = const [];
  
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    _searchController.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
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
          _filteredStaff = list;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được danh sách nhân viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStaff = _allStaff;
      } else {
        _filteredStaff = _allStaff.where((s) {
          return s.fullName.toLowerCase().contains(query) ||
                 (s.employeeId?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 1,
        title: const Text('Nhân viên chi nhánh', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhân viên...',
                  prefixIcon: const Icon(Icons.search, color: kMuted),
                  filled: true,
                  fillColor: kBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: kBorder),
            
            // List
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBrown));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: kDanger, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: kDanger)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: kBrown, foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (_filteredStaff.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'Chưa có nhân viên nào' : 'Không tìm thấy kết quả',
          style: const TextStyle(color: kMuted, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStaff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildStaffCard(_filteredStaff[i]),
    );
  }

  Widget _buildStaffCard(StaffRoster staff) {
    // Generate initials
    final names = staff.fullName.split(' ').where((s) => s.isNotEmpty).toList();
    String initials = '';
    if (names.isNotEmpty) {
      initials = names.first[0].toUpperCase();
      if (names.length > 1) {
        initials += names.last[0].toUpperCase();
      }
    }

    // Role colors
    final isManager = staff.role == 'STORE_MANAGER';
    final roleColor = isManager ? kBrownDark : kGold;
    
    // Status color
    final statusColor = staff.isActive ? kSuccess : kMuted;
    
    // PIN Status
    String pinStatusText = 'Chưa tạo PIN';
    Color pinColor = kMuted;
    IconData pinIcon = Icons.password;
    
    if (staff.pinLocked) {
      pinStatusText = 'Khóa PIN';
      pinColor = kDanger;
      pinIcon = Icons.lock;
    } else if (staff.pinSet) {
      pinStatusText = 'Đã tạo PIN';
      pinColor = kSuccess;
      pinIcon = Icons.check_circle;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: roleColor.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        staff.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBrownDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  staff.employeeId ?? 'Không có mã NV',
                  style: const TextStyle(color: kMuted, fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      text: _roleLabel(staff.role),
                      color: roleColor,
                      icon: isManager ? Icons.shield : Icons.badge,
                    ),
                    _buildBadge(
                      text: pinStatusText,
                      color: pinColor,
                      icon: pinIcon,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String text, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) => switch (r) {
        'STORE_MANAGER' => 'Quản lý',
        'CASHIER' => 'Thu ngân',
        'BARISTA' => 'Pha chế',
        _ => r,
      };
}
