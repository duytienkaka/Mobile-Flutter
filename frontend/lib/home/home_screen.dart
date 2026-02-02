import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fullName;

  @override
  void initState() {
    super.initState();
    _loadNameFromToken();
  }

  Future<void> _loadNameFromToken() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    final name = _readJwtClaim(token, 'unique_name');
    if (!mounted) return;
    setState(() => fullName = name);
  }

  String? _readJwtClaim(String token, String claimKey) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = _decodeBase64Url(parts[1]);
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      if (data is Map && data[claimKey] is String) {
        final value = data[claimKey] as String;
        return value.trim().isEmpty ? null : value;
      }
    } catch (_) {}
    return null;
  }

  String? _decodeBase64Url(String input) {
    try {
      final normalized = base64Url.normalize(input);
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.delete_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(fullName),
              const SizedBox(height: 20),
              const Text(
                'Recipes you can make',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=80',
                      title: 'Hawaiian Chicken Smoked\nPizza',
                      tags: const ['Mozzarella', 'Salame', '+8'],
                      time: '40 Min',
                      count: '12',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=800&q=80',
                      title: 'Hawaiian Chicken\nPizza',
                      tags: const ['Mozzarella', 'Salame', '+8'],
                      time: '40 Min',
                      count: '12',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
                      title: 'Grilled Chicken\nSalad',
                      tags: const ['Lettuce', 'Chicken', '+5'],
                      time: '25 Min',
                      count: '8',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=800&q=80',
                      title: 'Pasta Carbonara',
                      tags: const ['Pasta', 'Bacon', '+4'],
                      time: '30 Min',
                      count: '10',
                    ),
                    const SizedBox(width: 14),
                    _buildRecipeCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=800&q=80',
                      title: 'Avocado Toast',
                      tags: const ['Avocado', 'Egg', '+2'],
                      time: '15 Min',
                      count: '6',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Sắp hết hạn',
                      value: '0',
                      background: const Color(0xFFEDEDED),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Đã hết hạn',
                      value: '0',
                      background: const Color(0xFFD9D9D9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    final displayName = (name == null || name.trim().isEmpty)
        ? 'Hello!' : 'Hello $name! 👋';

    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFE7D7FF),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welcome back',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  static Widget _buildRecipeCard({
    required String imageUrl,
    required String title,
    required List<String> tags,
    required String time,
    required String count,
  }) {
    return SizedBox(
      width: 200,
      height: 210,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 88,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Pizza',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tags[i], style: const TextStyle(fontSize: 9)),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.black45),
                const SizedBox(width: 4),
                Text(time,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black54)),
                const SizedBox(width: 12),
                const Icon(Icons.list_alt, size: 12, color: Colors.black45),
                const SizedBox(width: 4),
                Text(count,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard({
    required String label,
    required String value,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
