String formatEventDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Chưa có lịch';
  if (start != null && end != null) {
    return '${_formatDateTime(start)} – ${_formatDateTime(end)}';
  }
  return _formatDateTime(start ?? end!);
}

String formatEventDate(DateTime? date) {
  if (date == null) return 'Chưa có lịch';
  return _formatDateTime(date);
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
