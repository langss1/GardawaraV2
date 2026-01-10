import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color Palette (Matched with GuardianHomeScreen)
final Color primaryDark = const Color(0xFF138066);
final Color primaryLight = const Color(0xFF00E5C5);

// 2. Activity Report Screen
class ActivityReportScreen extends StatelessWidget {
  final List<Map<String, String>> history;
  final int blockedCount;

  const ActivityReportScreen({
    super.key,
    this.history = const [],
    this.blockedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Laporan & Riwayat',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90, // Spacious
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body:
          history.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada riwayat aktivitas.",
                      style: GoogleFonts.leagueSpartan(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: history.length + 1, // +1 for the summary header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return EntryItem(
                      index: 0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Diblokir",
                              style: GoogleFonts.leagueSpartan(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "$blockedCount Situs",
                              style: GoogleFonts.leagueSpartan(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final item = history[index - 1];
                  return EntryItem(
                    index: index,
                    child: _buildReportItem(
                      context,
                      "Blokir Konten",
                      "${item['url']} mencoba diakses",
                      item['time'] ?? 'Baru saja',
                      Colors.red,
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    String title,
    String desc,
    String time,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Prepare details
            String websiteName = title;
            String clockTime = "-";
            String dayName = "-";
            String fullDate = time;

            // Extract Name from Desc if possible (Desc is usually URL)
            if (desc.contains(" mencoba diakses")) {
              websiteName = desc.replaceAll(" mencoba diakses", "");
            }

            try {
              final now = DateTime.now();
              // Format incoming: HH:mm, dd/MM
              final parts = time.split(", ");
              if (parts.length == 2) {
                clockTime = parts[0]; // 09:16
                final dateParts = parts[1].split("/"); // 07/01
                if (dateParts.length == 2) {
                  int day = int.parse(dateParts[0]);
                  int month = int.parse(dateParts[1]);
                  final parsedDate = DateTime(now.year, month, day);

                  // Manual Day Name (Indonesian)
                  const days = [
                    "Senin",
                    "Selasa",
                    "Rabu",
                    "Kamis",
                    "Jumat",
                    "Sabtu",
                    "Minggu",
                  ];
                  dayName = days[parsedDate.weekday - 1];

                  const months = [
                    "Januari",
                    "Februari",
                    "Maret",
                    "April",
                    "Mei",
                    "Juni",
                    "Juli",
                    "Agustus",
                    "September",
                    "Oktober",
                    "November",
                    "Desember",
                  ];
                  fullDate = "$day ${months[month - 1]} ${now.year}";
                }
              }
            } catch (_) {}

            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Dismiss",
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (context, _, __) {
                return Center(child: Container());
              },
              transitionBuilder: (context, anim, secondaryAnim, child) {
                return FadeTransition(
                  opacity: anim,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Red
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 32,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Akses Diblokir",
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Situs ini terdeteksi mengandung konten judi",
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 12,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Body
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogDetailItem(
                                "Nama Website",
                                websiteName,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDialogDetailItem(
                                      "Waktu",
                                      clockTime,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDialogDetailItem(
                                      "Hari",
                                      dayName,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDialogDetailItem("Tanggal", fullDate),

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Tutup",
                                    style: GoogleFonts.leagueSpartan(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.block, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.leagueSpartan(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// 3. Change PIN Screen
class ChangePinScreen extends StatelessWidget {
  const ChangePinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Ubah PIN',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'Perbarui PIN Keamanan',
              style: GoogleFonts.leagueSpartan(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan PIN baru mudah diingat namun sulit ditebak.',
              textAlign: TextAlign.center,
              style: GoogleFonts.leagueSpartan(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 40),
            _buildPinField("PIN Lama", false),
            const SizedBox(height: 20),
            _buildPinField("PIN Baru", true),
            const SizedBox(height: 20),
            _buildPinField("Konfirmasi PIN Baru", true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'PIN Berhasil Diubah',
                        style: GoogleFonts.leagueSpartan(),
                      ),
                      backgroundColor: primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  elevation: 5,
                  shadowColor: primaryDark.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(String label, bool isNew) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: "••••",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            suffixIcon:
                isNew
                    ? const Icon(
                      Icons.visibility_off_outlined,
                      color: Colors.grey,
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}

// 4. Entry Animation Item Helper
class EntryItem extends StatefulWidget {
  final Widget child;
  final int index;
  const EntryItem({super.key, required this.child, required this.index});

  @override
  State<EntryItem> createState() => _EntryItemState();
}

class _EntryItemState extends State<EntryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _translate = Tween(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _translate.value),
              child: widget.child,
            ),
          ),
    );
  }
}
