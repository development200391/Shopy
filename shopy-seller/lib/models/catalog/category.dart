class Category {
  final String id;
  final String name;
  final String slug;
  final String? parentCategoryId;

  const Category({required this.id, required this.name, required this.slug, this.parentCategoryId});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
    );
  }
}
