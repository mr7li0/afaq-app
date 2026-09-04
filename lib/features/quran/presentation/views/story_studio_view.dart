import 'package:flutter/material.dart';

class StoryStudioView extends StatelessWidget {
  final dynamic verse;
  const StoryStudioView({super.key, this.verse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استوديو القصص')),
      body: const Center(child: Text('قريباً')),
    );
  }
}
