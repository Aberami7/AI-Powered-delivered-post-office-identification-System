import 'package:flutter/material.dart';
import 'search_page.dart';
import 'nearby.dart';
import 'chatbot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PostFinderHome(),
    );
  }
}

class PostFinderHome extends StatelessWidget {
  const PostFinderHome({super.key});

  static const Color emeraldGreen = Color(0xFF50C878);
  static const Color lightEmerald = Color(0xFFE8F8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Text("📮", style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text(
              "PostFinder AI",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),

        /// ROBOT ICON
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AIChatbotPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: lightEmerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: emeraldGreen,
                  size: 26,
                ),
              ),
            ),
          )
        ],

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F2F6)),
        ),
      ),

      /// BODY
      body: Column(
        children: [

          const SizedBox(height: 40),

          /// TITLE
          const Center(
            child: Column(
              children: [
                Text(
                  "Identify and Locate",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Postal Services Instantly",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: emeraldGreen,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text(
              "Our AI-powered platform helps you discover postal codes, track logistics, and find nearby centers with pinpoint accuracy.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 30),

          /// ✅ CENTER CONTAINERS (FIXED)
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.symmetric(horizontal: 40),

                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 2,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 25,
                  physics: const NeverScrollableScrollPhysics(),

                  children: [

                    HoverCard(
                      child: _buildMenuCard(
                        context,
                        Icons.search,
                        "Search",
                        "Quickly search for any area's pincode and get detailed office locations instantly",
                        const PostSearchPage(),
                      ),
                    ),

                    HoverCard(
                      child: _buildMenuCard(
                        context,
                        Icons.location_on_outlined,
                        "Nearby",
                        "Discover the closest post offices based on your current live GPS location",
                        const NearbyPage(),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          /// STATS
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatItem("99%", "Accuracy"),
              StatItem("1.5L+", "Post Offices"),
              StatItem("24/7", "Availability"),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  static Widget _buildMenuCard(
      BuildContext context,
      IconData icon,
      String title,
      String sub,
      Widget page) {

    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (context) => page)),

      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F2F6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: lightEmerald,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: emeraldGreen,
                size: 28,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;
  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHover
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String value;
  final String label;

  const StatItem(this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: PostFinderHome.emeraldGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}