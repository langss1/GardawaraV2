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
    this.blockedCount = 0
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Laporan & Riwayat', style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: history.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Belum ada riwayat aktivitas.", style: GoogleFonts.leagueSpartan(color: Colors.grey)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: history.length + 1, // +1 for the summary header
            itemBuilder: (context, index) {
              if (index == 0) {
                 return Container(
                   margin: const EdgeInsets.only(bottom: 20),
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: primaryDark,
                     borderRadius: BorderRadius.circular(16),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("Total Diblokir", style: GoogleFonts.leagueSpartan(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                       Text("$blockedCount Situs", style: GoogleFonts.leagueSpartan(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                     ],
                   ),
                 );
              }
              final item = history[index - 1];
              return _buildReportItem(
                "Blokir Konten", 
                "${item['url']} mencoba diakses", 
                item['time'] ?? 'Baru saja', 
                Colors.red
              );
            },
          ),
    );
  }

  Widget _buildReportItem(String title, String desc, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
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
                Text(title, style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.leagueSpartan(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.leagueSpartan(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
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
        title: Text('Ubah PIN', style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, color: Colors.black87)),
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
              style: GoogleFonts.leagueSpartan(fontSize: 22, fontWeight: FontWeight.bold),
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
                      content: Text('PIN Berhasil Diubah', style: GoogleFonts.leagueSpartan()),
                      backgroundColor: primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  elevation: 5,
                  shadowColor: primaryDark.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Simpan Perubahan', style: GoogleFonts.leagueSpartan(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text(label, style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: "••••",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            suffixIcon: isNew ? const Icon(Icons.visibility_off_outlined, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }
}
