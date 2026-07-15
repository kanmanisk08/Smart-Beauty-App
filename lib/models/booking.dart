class Booking {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String serviceName;
  final double price;
  final int duration;
  String date; // YYYY-MM-DD
  String time; // e.g. "11:00 AM"
  final String stylist;
  String status; // "Pending", "Confirmed", "Declined", "History"
  final double loyaltyDiscount;
  final double tax;
  final double totalPaid;
  final int pointsApplied;
  final int pointsEarned;
  Map<String, dynamic>? liveStatus; // delay properties
  String? review; // Custom customer review

  /// ISO-8601 timestamp of when the owner actually pressed Start. Null until
  /// then — the session timer is derived from this, so it survives reloads.
  String? startedAt;

  /// Extra minutes the owner granted mid-session via "+5 / +10".
  int addedMinutes;

  Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.date,
    required this.time,
    required this.stylist,
    required this.status,
    required this.loyaltyDiscount,
    required this.tax,
    required this.totalPaid,
    required this.pointsApplied,
    required this.pointsEarned,
    this.liveStatus,
    this.review,
    this.startedAt,
    this.addedMinutes = 0,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      serviceName: json['serviceName'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as int,
      date: json['date'] as String,
      time: json['time'] as String,
      stylist: json['stylist'] as String? ?? 'Selvi',
      status: json['status'] as String? ?? 'Pending',
      loyaltyDiscount: (json['loyaltyDiscount'] as num? ?? 0).toDouble(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      pointsApplied: json['pointsApplied'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      liveStatus: json['liveStatus'] != null ? Map<String, dynamic>.from(json['liveStatus'] as Map) : null,
      review: json['review'] as String?,
      startedAt: json['startedAt'] as String?,
      addedMinutes: (json['addedMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'serviceName': serviceName,
      'price': price,
      'duration': duration,
      'date': date,
      'time': time,
      'stylist': stylist,
      'status': status,
      'loyaltyDiscount': loyaltyDiscount,
      'tax': tax,
      'totalPaid': totalPaid,
      'pointsApplied': pointsApplied,
      'pointsEarned': pointsEarned,
      'liveStatus': liveStatus,
      'review': review,
      'startedAt': startedAt,
      'addedMinutes': addedMinutes,
    };
  }
}
