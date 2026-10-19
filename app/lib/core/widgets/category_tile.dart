import 'package:flutter/material.dart';
import '../../data/models/category.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.category, super.key});
  final Category category;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('${category.lecturesCount}'),
        ],
      ),
    ),
  );
}
