/// Optimizes remote image URLs for small dashboard list tiles.
///
/// Cloudinary: inserts width + auto quality after `/image/upload/`.
/// Other hosts: returned unchanged.
String dashboardListImageUrl(String url, {int maxWidth = 480}) {
  final u = url.trim();
  if (u.isEmpty) return u;
  final lower = u.toLowerCase();
  if (!lower.contains('cloudinary.com/image/upload/')) return u;
  if (u.contains('/image/upload/w_')) return u;
  return u.replaceFirst(
    '/image/upload/',
    '/image/upload/w_$maxWidth,q_auto,f_auto/',
  );
}
