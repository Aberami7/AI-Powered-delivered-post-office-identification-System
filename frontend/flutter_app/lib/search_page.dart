import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PostSearchPage extends StatefulWidget {
  const PostSearchPage({super.key});

  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  bool _isLoading = false;

  static const Color emeraldGreen = Color(0xFF50C878);

 final String backendUrl = "http://10.220.51.118:5000/search";

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ✅ UPDATED FUNCTION (optimized navigation)
  Future<void> _openInMap(
      String officeName,
      String city,
      String state,
      String pincode) async {

    final query = Uri.encodeComponent(
        "$officeName, $city, $state $pincode, India");

    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving&dir_action=navigate",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open Google Maps";
    }
  }

  Future<void> _processImage(XFile image) async {

    setState(() => _isLoading = true);

    final inputImage = InputImage.fromFilePath(image.path);

    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    RegExp pincodeRegex = RegExp(r'\b\d{6}\b');

    String? foundPincode;

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {

        if (pincodeRegex.hasMatch(line.text)) {

          foundPincode = pincodeRegex.firstMatch(line.text)?.group(0);
          break;
        }
      }
    }

    if (foundPincode != null) {

      _searchController.text = foundPincode;

      _handleSearch(foundPincode);

    } else {

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Pincode found in image")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image == null) return;

    Navigator.pop(context);

    _processImage(image);
  }

  void _showImageSourceDialog() {

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text(
              "AI Scanner",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.camera_alt, color: emeraldGreen),
              title: const Text("Camera"),
              onTap: () => _pickImage(ImageSource.camera),
            ),

            ListTile(
              leading: const Icon(Icons.image, color: emeraldGreen),
              title: const Text("Gallery"),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSearch(String query) async {

    query = query.trim();

    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {

      final response =
          await http.get(Uri.parse("$backendUrl?query=${query.toLowerCase()}"));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {

          _results = data["postoffices"] ?? [];
          _isLoading = false;
        });
      }

    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF9FBFA),

      body: SafeArea(

        child: Column(

          children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                children: [

                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const Center(
                    child: Column(
                      children: [

                        Text(
                          "Search Post Office",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "Enter Pincode or Area",
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * .6,
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  children: [

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 45,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: emeraldGreen.withOpacity(.15)),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.location_on,
                            color: emeraldGreen,
                            size: 20,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Enter area or pincode",
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) => _handleSearch(val),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: emeraldGreen,
                            ),
                            onPressed: () =>
                                _handleSearch(_searchController.text),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    InkWell(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: const Column(
                          children: [

                            Icon(
                              Icons.qr_code_scanner,
                              color: emeraldGreen,
                              size: 30,
                            ),

                            SizedBox(height: 10),

                            Text(
                              "Scan Address Label",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),

                            Text(
                              "AI will automatically find pincode",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: emeraldGreen),
                    )
                  : _results.isEmpty
                      ? const Center(
                          child:
                              Text("No results found. Try scanning!"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _results.length,
                          itemBuilder: (context, index) =>
                              _buildCard(_results[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic office) {

    String insight =
        office["ai_insight"] ??
        "Reliable postal service center supporting nearby communities.";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                emeraldGreen.withOpacity(.1),
            child: const Icon(
              Icons.mail_outline,
              color: emeraldGreen,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  office["name"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),

                Text(
                  "${office["city"]}, ${office["state"]} - ${office["pincode"]}",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Text(
                  insight,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.near_me,
              color: emeraldGreen,
            ),
            onPressed: () => _openInMap(
              office["name"],
              office["city"],
              office["state"],
              office["pincode"],
            ),
          )
        ],
      ),
    );
  }
}