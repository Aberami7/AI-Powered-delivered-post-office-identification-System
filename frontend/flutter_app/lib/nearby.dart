import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {

  final String apiUrl = "http://10.87.141.118:5000";

  List offices = [];
  bool isLoading = true;

  String insight = "Finding nearby post offices...";
  String locationText = "";

  static const Color emeraldGreen = Color(0xFF50C878);

  @override
  void initState() {
    super.initState();
    _fetchLocationAndData();
  }

  // ---------------- FETCH LOCATION + API ----------------

  Future<void> _fetchLocationAndData() async {

    setState(() {
      isLoading = true;
      insight = "Getting your location...";
    });

    try {

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location services disabled";
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission denied";
      }

      // ✅ Better GPS accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // ✅ Debug prints
      print("Latitude: ${position.latitude}");
      print("Longitude: ${position.longitude}");

      locationText =
          "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";

      final response = await http.get(
        Uri.parse(
            "$apiUrl/nearest?lat=${position.latitude}&lon=${position.longitude}"),
      );

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {
          offices = data["offices"] ?? [];
          insight = "Nearest Post Offices";
          isLoading = false;
        });

      } else {
        throw "Server error";
      }

    } catch (e) {

      print(e);

      setState(() {
        insight = "Unable to fetch nearby offices";
        offices = [];
        isLoading = false;
      });
    }
  }

  // ---------------- OPEN GOOGLE MAPS ----------------

  Future<void> _openMaps(double lat, double lon) async {

    final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),

      body: SafeArea(
        child: Column(
          children: [

            _buildHeader(),

            Expanded(
              child: isLoading
                  ? _buildLoading()
                  : offices.isEmpty
                      ? _buildError()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),

      child: Row(
        children: [

          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Nearby Post Offices",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              Text(
                isLoading ? "Locating..." : locationText,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLoading() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const CircularProgressIndicator(color: emeraldGreen),

          const SizedBox(height: 15),

          Text(
            insight,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(Icons.location_off, size: 60, color: Colors.grey),

          const SizedBox(height: 15),

          const Text("No nearby offices found"),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: _fetchLocationAndData,
            style: ElevatedButton.styleFrom(
              backgroundColor: emeraldGreen,
            ),
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  Widget _buildResults() {

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: offices.length + 1,
      itemBuilder: (context, index) {

        if (index == 0) {
          return _buildInsightBox();
        }

        return _buildOfficeCard(offices[index - 1]);
      },
    );
  }

  Widget _buildInsightBox() {

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: emeraldGreen.withOpacity(.08),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [

          const Icon(Icons.auto_awesome, color: emeraldGreen),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                color: emeraldGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeCard(dynamic office) {

    double lat = double.tryParse(office["latitude"].toString()) ?? 0;
    double lon = double.tryParse(office["longitude"].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Icon(Icons.local_post_office,
                  color: emeraldGreen, size: 18),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  office["name"] ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),

              Text(
                office["distance"] ?? "",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            "${office["city"]} - ${office["pincode"]}",
            style: const TextStyle(
                color: emeraldGreen, fontSize: 12),
          ),

          const SizedBox(height: 10),

          Text(
            office["ai_insight"] ?? "",
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.directions, color: emeraldGreen),
              onPressed: () => _openMaps(lat, lon),
            ),
          )
        ],
      ),
    );
  }
}