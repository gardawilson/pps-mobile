import 'package:flutter/material.dart';
import 'package:pps_mobile/shared/components/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _background = Color(0xFFF1F5F9);
  static const Color _ink = Color(0xFF1E293B);
  static const Color _slate = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _QuickAccessItem {
  final String route;
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAccessItem({
    required this.route,
    required this.icon,
    required this.label,
    required this.color,
  });
}

const List<_QuickAccessItem> _quickAccess = [
  _QuickAccessItem(
    route: '/stockopname',
    icon: Icons.checklist_rtl_rounded,
    label: 'Stock Opname',
    color: HomeScreen._primary,
  ),
  _QuickAccessItem(
    route: '/stockopname-v2',
    icon: Icons.inventory_2_outlined,
    label: 'SO V2',
    color: Color(0xFF5B21B6),
  ),
  _QuickAccessItem(
    route: '/mapping-v2',
    icon: Icons.map_rounded,
    label: 'Mapping V2',
    color: Color(0xFF0369A1),
  ),
  _QuickAccessItem(
    route: '/bj-jual',
    icon: Icons.sell_rounded,
    label: 'Penjualan BJ',
    color: Color(0xFF92400E),
  ),
];

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openModule(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool? confirmExit = await _showExitDialog(context);
        return confirmExit ?? false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: HomeScreen._background,
        drawer: const AppDrawer(currentRoute: '/home'),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                context,
                () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('RINGKASAN'),
                    const SizedBox(height: 12),
                    _buildStatGrid(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('AKSES CEPAT'),
                    const SizedBox(height: 12),
                    _buildQuickAccess(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('AKTIVITAS TERBARU'),
                    const SizedBox(height: 12),
                    _buildActivityPlaceholder(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: HomeScreen._slate,
        letterSpacing: 1.4,
      ),
    );
  }

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get _todayFormatted {
    final now = DateTime.now();
    return '${_dayNames[now.weekday - 1]}, ${now.day} ${_monthNames[now.month - 1]} ${now.year}';
  }

  Widget _buildHeader(BuildContext context, VoidCallback onMenuTap) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        20,
      ),
      color: HomeScreen._primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderIconButton(icon: Icons.menu_rounded, onPressed: onMenuTap),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Warehouse Management System',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  _todayFormatted,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    const stats = [
      (
        label: 'Stock Opname Aktif',
        icon: Icons.checklist_rtl_rounded,
        color: HomeScreen._primary,
      ),
      (
        label: 'Total Lokasi',
        icon: Icons.location_on_rounded,
        color: Color(0xFF0F766E),
      ),
      (
        label: 'Item Discan Hari Ini',
        icon: Icons.qr_code_scanner_rounded,
        color: Color(0xFF0369A1),
      ),
      (
        label: 'Transaksi Pending',
        icon: Icons.pending_actions_rounded,
        color: Color(0xFF92400E),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats
          .map((s) => _StatCard(label: s.label, icon: s.icon, color: s.color))
          .toList(),
    );
  }

  Widget _buildQuickAccess() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 14,
      childAspectRatio: 0.8,
      children: _quickAccess
          .map(
            (item) => _QuickAccessTile(
              icon: item.icon,
              label: item.label,
              color: item.color,
              onTap: () => _openModule(item.route),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActivityPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeScreen._border),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HomeScreen._slate.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: HomeScreen._slate,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada aktivitas',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: HomeScreen._ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Riwayat transaksi akan ditampilkan di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: HomeScreen._slate),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          const Text(
            '–',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HomeScreen._ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: HomeScreen._slate),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: HomeScreen._ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
