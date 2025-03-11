import 'package:flutter/material.dart';

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lig Durumu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mevcut Lig
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bronze Lig',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Sıralama: #1234'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tüm Ligler
            const Text(
              'Ligler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildLeagueItem('Legend', Colors.purple, '10M Gold'),
                  _buildLeagueItem('Grandmaster', Colors.red, '2.5M Gold'),
                  _buildLeagueItem('Master', Colors.pink, '750K Gold'),
                  _buildLeagueItem('Diamond', Colors.cyan, '250K Gold'),
                  _buildLeagueItem('Platinum', Colors.blue, '75K Gold'),
                  _buildLeagueItem('Gold', Colors.amber, '25K Gold'),
                  _buildLeagueItem('Silver', Colors.grey, '10K Gold'),
                  _buildLeagueItem('Bronze', Colors.brown, '2.5K Gold'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueItem(String name, MaterialColor color, String requirement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color[300],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
          ),
        ),
        title: Text(name),
        subtitle: Text(requirement),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}