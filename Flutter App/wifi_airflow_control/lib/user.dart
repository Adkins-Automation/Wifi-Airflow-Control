class User {
  final int? uid;
  final String name;
  final String photoUrl;

  User({this.uid, required this.name, required this.photoUrl});

  factory User.fromMap(Map<String, dynamic> json) =>
      User(uid: json['uid'], name: json['name'], photoUrl: json['photoUrl']);

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'photoUrl': photoUrl};
  }
}
