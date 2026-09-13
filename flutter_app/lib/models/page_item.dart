class PageItem {
  final String id;
  String name;
  String url;
  int order;
  String ua; // 'mobile' | 'desktop'

  PageItem({
    required this.id,
    required this.name,
    required this.url,
    required this.order,
    this.ua = 'mobile',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'url': url, 'order': order, 'ua': ua};

  factory PageItem.fromJson(Map<String, dynamic> j) => PageItem(
        id: j['id'] as String,
        name: j['name'] as String,
        url: j['url'] as String,
        order: (j['order'] as num).toInt(),
        ua: (j['ua'] as String?) ?? 'mobile',
      );
}
