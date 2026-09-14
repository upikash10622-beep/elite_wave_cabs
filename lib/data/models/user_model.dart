class UserModel {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String? profilePic;

  UserModel(
      {required this.uid,
      required this.phoneNumber,
      this.displayName = "User",
      this.profilePic});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phoneNumber': phoneNumber,
        'displayName': displayName,
        'profilePic': profilePic
      };
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? "User",
      profilePic: map['profilePic']);
}
