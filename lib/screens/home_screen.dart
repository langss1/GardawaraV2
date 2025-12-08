import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  bool isProtected = true;
  bool hasData = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      body: Stack(
        children: [

          _buildHeaderBackground(),


          SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 320), 
                
                // Content Body
                _buildContentBody(),
                
                const SizedBox(height: 80),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: _buildChatBotButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return SizedBox(
      height: 400, 
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map Image
          Image.asset(
            isProtected 
                ? 'assets/images/Peta_Unlocked.png' 
                : 'assets/images/Peta_Locked.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!isProtected) ...[
                  const Icon(Icons.lock_open_rounded, color: Colors.white, size: 32),
                   Text(
                    'Anda tidak terproteksi dari Judi',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '5700+ website judi ditemukan',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Anda Terproteksi',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Toggle Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9A7), Color(0xFF00897B)], // Green/Teal Gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERLINDUNGAN GARDA WARA',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProtected 
                          ? 'Perlindungan Aman' 
                          : 'Perlindungan Tidak Aktif',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isProtected,
                    onChanged: (val) {
                      setState(() {
                        isProtected = val;
                      });
                    },
                    activeColor: Colors.blue, // Icon color inside switch
                    activeTrackColor: Colors.white,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Garda Wara Memerlukan akses izin aksebilitas untuk mencegah membuka situs atau aplikasi judi',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Stats Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8E2), // Light greenish/beige tint
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading Stats
                Row(
                  children: [
                    Text(
                      isProtected ? (hasData ? '124' : '0') : '0',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Website Judi Terblokir',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            isProtected 
                              ? 'Perlindungan Aman dengan AI Gardawara'
                              : 'Segera Aktifkan Gardawara',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Divider(color: Colors.black.withOpacity(0.1), thickness: 1.5),
                const SizedBox(height: 16),

                Text(
                  'Riwayat Pemblokiran',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),

                // Content Area (List or Empty State)
                if (isProtected)
                  if (hasData)
                    _buildBlockedList()
                  else
                    _buildEmptyStateProtected()
                else
                  _buildEmptyStateUnprotected(),
                  
                if (isProtected && hasData) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lihat Selengkapnya',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateUnprotected() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.gpp_bad_rounded,
              size: 80,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Segera Aktifkan Gardawara!',
            style: GoogleFonts.leagueSpartan(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildEmptyStateProtected() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gardawara tidak mendeteksi apapun',
            style: GoogleFonts.leagueSpartan(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    // Dummy Data
    final blockedSites = [
      {'url': 'slotgacor.com', 'time': '15:10, 22/10/2025'},
      {'url': 'slototo.com', 'time': '15:10, 22/10/2025'},
      {'url': 'gacor.com', 'time': '15:10, 22/10/2025'},
      {'url': 'toto.com', 'time': '15:10, 22/10/2025'},
      {'url': 'slot24.com', 'time': '15:10, 22/10/2025'},
      {'url': 'gacor21.com', 'time': '15:10, 22/10/2025'},
      {'url': 'gacor31.com', 'time': '15:10, 22/10/2025'},
    ];

    return Column(
      children: blockedSites.map((site) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                site['url']!,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                site['time']!,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatBotButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF00B0FF), // Light Blue
        borderRadius: BorderRadius.circular(20), // Squarish rounded
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
