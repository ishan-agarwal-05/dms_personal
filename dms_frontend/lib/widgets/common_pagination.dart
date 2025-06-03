import 'package:flutter/material.dart';

class CommonPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final VoidCallback? onFirstPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onLastPage;

  const CommonPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    this.onFirstPage,
    this.onPreviousPage,
    this.onNextPage,
    this.onLastPage,
  });

  @override
  Widget build(BuildContext context) {
    final int startIndex = (currentPage - 1) * itemsPerPage + 1;
    int endIndex = startIndex + itemsPerPage - 1;
    if (endIndex > totalItems) {
      endIndex = totalItems;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Items per page: $itemsPerPage',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 20),
          Text(
            '$startIndex-$endIndex of $totalItems',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.first_page,
                  color: currentPage == 1 ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: currentPage == 1 ? null : onFirstPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: currentPage == 1 ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: currentPage == 1 ? null : onPreviousPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: currentPage == totalPages
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                onPressed: currentPage == totalPages ? null : onNextPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.last_page,
                  color: currentPage == totalPages
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                onPressed: currentPage == totalPages ? null : onLastPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}