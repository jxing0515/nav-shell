bool isValidUrl(String url) {
  final u = Uri.tryParse(url.trim());
  return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty;
}

bool isValidName(String name) {
  final n = name.trim();
  return n.isNotEmpty && n.length <= 20;
}
