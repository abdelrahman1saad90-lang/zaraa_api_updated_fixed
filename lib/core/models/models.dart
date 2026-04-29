import '../constants/app_strings.dart';

// ============================================================
// USER MODEL
// ============================================================
class UserModel {
  final String id;
  final String fullName;
  final String userName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? avatarUrl;
  final String? planType;
  final String? token;        // AccessToken (JWT)
  final String? refreshToken;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.email,
    this.phoneNumber,
    this.address,
    this.avatarUrl,
    this.planType,
    this.token,
    this.refreshToken,
  });

  /// Returns initials like "AS" from "Abdelrahman Saad"
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }

  /// Build from Profile endpoint response.
  /// [accessToken] and [refreshToken] are stored alongside.
  factory UserModel.fromProfileJson(
    Map<String, dynamic> json, {
    String? accessToken,
    String? refreshToken,
  }) {
    return UserModel(
      id: json['applicationUserId']?.toString() ?? '',
      fullName: json['name'] ?? json['userName'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      planType: 'Basic',
      token: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? json['userName'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      avatarUrl: json['avatarUrl'],
      planType: json['planType'] ?? 'Basic',
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'avatarUrl': avatarUrl,
        'planType': planType,
        'token': token,
        'refreshToken': refreshToken,
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? userName,
    String? email,
    String? phoneNumber,
    String? address,
    String? avatarUrl,
    String? planType,
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      planType: planType ?? this.planType,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

// ============================================================
// PLANT MODEL — available species for diagnosis
// ============================================================
class PlantModel {
  final String id;
  final String name;
  final String imageUrl;

  const PlantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  static List<PlantModel> get defaultPlants => [
        const PlantModel(
          id: 'apple',
          name: 'Apple',
          imageUrl:
              'https://images.unsplash.com/photo-1607305387299-a3d9611cd469?w=300',
        ),
        const PlantModel(
          id: 'cherry',
          name: 'Cherry',
          imageUrl:
              'https://paradisenursery.com/cdn/shop/files/royal-crimson-cherry-tree-scaled.jpg?v=1698885070&w=300',
        ),
        const PlantModel(
          id: 'corn',
          name: 'Corn',
          imageUrl:
              'https://hgtvhome.sndimg.com/content/dam/images/hgtv/stock/2018/4/3/0/shutterstock_Chutharat-Kamkhuntee_683363251_corn-growing.jpg.rend.hgtvcom.1280.960.85.suffix/1522768591804.webp',
        ),
        const PlantModel(
          id: 'tomato',
          name: 'Tomato',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_je.jpg',
        ),
        const PlantModel(
          id: 'grape',
          name: 'Grape',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Table_grapes_on_the_vine.jpg/1280px-Table_grapes_on_the_vine.jpg',
        ),
        const PlantModel(
          id: 'peach',
          name: 'Peach',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Autumn_Red_peaches.jpg/1280px-Autumn_Red_peaches.jpg',
        ),
        const PlantModel(
          id: 'pepper',
          name: 'Pepper',
          imageUrl:
              'https://snaped.fns.usda.gov/sites/default/files/seasonal-produce/2018-05/bell%20peppers.jpg',
        ),
        const PlantModel(
          id: 'potato',
          name: 'Potato',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/a/ab/Patates.jpg',
        ),
        const PlantModel(
          id: 'strawberry',
          name: 'Strawberry',
          imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/PerfectStrawberry.jpg/1280px-PerfectStrawberry.jpg',
        ),
      ];
}

// ============================================================
// DIAGNOSIS MODEL — result of an AI scan
// ============================================================
class DiagnosisModel {
  final String id;
  final String plantName;
  final String? plantImageUrl;
  final String disease;
  final double confidence;
  final DiagnosisStatus status;
  final DateTime diagnosedAt;
  final String? treatment;
  final String? diagnosisCode;

  const DiagnosisModel({
    required this.id,
    required this.plantName,
    this.plantImageUrl,
    required this.disease,
    required this.confidence,
    required this.status,
    required this.diagnosedAt,
    this.treatment,
    this.diagnosisCode,
  });

  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(0)}%';

  String get formattedDate {
    final d = diagnosedAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = d.hour > 12 ? d.hour - 12 : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month]} ${d.day}, ${d.year} at '
        '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id']?.toString() ?? '',
      plantName: json['plantName'] ?? '',
      plantImageUrl: json['plantImageUrl'],
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      status: DiagnosisStatus.fromString(json['status'] ?? 'healthy'),
      diagnosedAt: json['diagnosedAt'] != null
          ? DateTime.parse(json['diagnosedAt'])
          : DateTime.now(),
      treatment: json['treatment'],
      diagnosisCode: json['diagnosisCode'],
    );
  }

  static List<DiagnosisModel> get sampleHistory => [
        DiagnosisModel(
          id: '1',
          plantName: 'Tomato',
          plantImageUrl:
              'https://images.unsplash.com/photo-1607305387299-a3d9611cd469?w=300',
          disease: 'Late Blight',
          confidence: 0.98,
          status: DiagnosisStatus.infected,
          diagnosedAt: DateTime(2026, 2, 5, 10, 30),
          treatment:
              'Apply copper-based fungicide every 7 days. Remove affected leaves.',
          diagnosisCode: 'DX-9021',
        ),
        DiagnosisModel(
          id: '2',
          plantName: 'Apple',
          plantImageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Red_Apple.jpg/960px-Red_Apple.jpg',
          disease: 'None (Healthy)',
          confidence: 0.99,
          status: DiagnosisStatus.healthy,
          diagnosedAt: DateTime(2026, 2, 1, 14, 20),
          treatment: 'No treatment needed. Continue regular care.',
          diagnosisCode: 'DX-8842',
        ),
        DiagnosisModel(
          id: '3',
          plantName: 'Corn',
          plantImageUrl:
              'https://cdn.britannica.com/36/167236-050-BF90337E/Ears-corn.jpg',
          disease: 'Common Rust',
          confidence: 0.92,
          status: DiagnosisStatus.recovering,
          diagnosedAt: DateTime(2026, 1, 25, 9, 15),
          treatment:
              'Apply triazole fungicide. Ensure good air circulation.',
          diagnosisCode: 'DX-7721',
        ),
      ];
}

enum DiagnosisStatus {
  healthy,
  infected,
  recovering;

  static DiagnosisStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'healthy':
        return DiagnosisStatus.healthy;
      case 'infected':
        return DiagnosisStatus.infected;
      case 'recovering':
        return DiagnosisStatus.recovering;
      default:
        return DiagnosisStatus.healthy;
    }
  }

  String get label {
    switch (this) {
      case DiagnosisStatus.healthy:
        return 'Healthy';
      case DiagnosisStatus.infected:
        return 'Infected';
      case DiagnosisStatus.recovering:
        return 'Recovering';
    }
  }
}

// ============================================================
// CATEGORY MODEL — from /api/Admin/Categories/Index
// ============================================================
class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final bool status;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.status = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['categoryId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'status': status,
      };
}

// ============================================================
// PRODUCT MODEL — shop items from AgriCureSystem API
// ============================================================
class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double discountedPrice;
  final String category;
  final String? brand;
  final double rating;
  final int reviewCount;
  final bool isOrganic;
  final bool isSoldOut;
  final double discount;   // 0–100
  final int quantity;
  final String? description;
  final String? currency;

  const ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discountedPrice,
    required this.category,
    this.brand,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isOrganic = false,
    this.isSoldOut = false,
    this.discount = 0,
    this.quantity = 0,
    this.description,
    this.currency = 'EGP',
  });

  String get displayPrice => '${currency ?? 'EGP'} ${discountedPrice.toStringAsFixed(2)}';

  /// Map from AgriCureSystem API product object
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? 0.0).toDouble();
    final discountPct = (json['discount'] ?? 0.0).toDouble();
    final discounted = price - price * (discountPct / 100);
    final qty = (json['quantity'] ?? 0) as int;

    return ProductModel(
      id: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: ApiConstants.imageUrl(json['mainImg']),
      price: price,
      discountedPrice: discounted,
      discount: discountPct,
      category: (json['category'] as Map<String, dynamic>?)?['name'] ?? '',
      brand: (json['brand'] as Map<String, dynamic>?)?['name'],
      rating: (json['rate'] ?? 4.5).toDouble(),
      reviewCount: json['traffic'] ?? 0,
      isSoldOut: qty <= 0,
      quantity: qty,
      description: json['description'],
      currency: 'EGP',
    );
  }

  /// Fallback sample products (used when API is unavailable)
  static List<ProductModel> get sampleProducts => [
        const ProductModel(
          id: '1',
          name: 'Roundup Weed and Grass Killer with Comfort Wand, 1 gal.',
          imageUrl:
              'https://i5.walmartimages.com/seo/Roundup-Weed-and-Grass-Killer4-with-Comfort-Wand-For-Flower-Beds-and-Trees-1-gal_0e92a490-074c-4382-b7ff-b58eaedc2ea2.da2b6a1fd75183d525ecd2875b20dcb0.jpeg',
          price: 18.50,
          discountedPrice: 18.50,
          category: 'Fungicide',
          rating: 4.8,
          reviewCount: 24,
          isOrganic: true,
        ),
        const ProductModel(
          id: '2',
          name: 'Garden Tech Daconil Fungicide 3-Way Control, 32 oz',
          imageUrl:
              'https://i5.walmartimages.com/seo/Garden-Tech-Daconil-Fungicide-3-Way-Control-Ready-to-Use-Spray-32-oz-1-Spray-Bottle_0227bc86-35e6-457a-b746-5344772bf0b0.41ce1004298feef15a1ae76c2d5a1a74.jpeg',
          price: 24.00,
          discountedPrice: 24.00,
          category: 'Fungicide',
          rating: 4.9,
          reviewCount: 24,
          isOrganic: true,
        ),
        const ProductModel(
          id: '3',
          name: 'Monterey Liqui-Cop Copper Fungicide Concentrate, 8 oz',
          imageUrl:
              'https://i5.walmartimages.com/seo/Monterey-Liqui-Cop-Outdoor-Copper-Fungicide-Concentrate-Liquid-8-oz_8388208e-50de-4cc8-bda6-c6652ff7eb6f.86670ce378c2befe9970bc1cc2925245.jpeg',
          price: 45.00,
          discountedPrice: 45.00,
          category: 'Fungicide',
          rating: 4.6,
          reviewCount: 24,
        ),
        const ProductModel(
          id: '4',
          name: 'Turf Builder Triple Action, 12,000 sq. ft. Lawn Fertilizer',
          imageUrl:
              'https://i5.walmartimages.com/seo/Turf-Builder-Triple-Action1-12-000-sq-ft-Lawn-Fertilizer-with-Weed-Control-and-Preventer_a4b3bfef-d51e-4354-a6cd-9d049c358c31.4827a2e309ff071019bcf7149fd4377c.jpeg',
          price: 35.99,
          discountedPrice: 35.99,
          category: 'Fertilizers',
          rating: 4.7,
          reviewCount: 24,
        ),
        const ProductModel(
          id: '5',
          name: 'Ortho Home Defense Max Indoor Insect Barrier, 1 gal.',
          imageUrl:
              'https://i5.walmartimages.com/seo/Ortho-Home-Defense-Max-Indoor-Insect-Barrier-with-Extended-Reach-Comfort-Wand-1-gal_e137997b-1ed8-4694-8e63-4aa56199d68e.1ce25b2921fe61809c89a49fb62d0c78.jpeg',
          price: 12.00,
          discountedPrice: 12.00,
          category: 'Pesticides',
          rating: 4.2,
          reviewCount: 24,
          isSoldOut: true,
        ),
      ];
}

// ============================================================
// CART ITEM MODEL — from /api/Customer/Carts/Index
// ============================================================
class CartItemModel {
  final String applicationUserId;
  final int productId;
  final ProductModel product;
  final int count;

  const CartItemModel({
    required this.applicationUserId,
    required this.productId,
    required this.product,
    required this.count,
  });

  double get subtotal => product.discountedPrice * count;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      applicationUserId: json['applicationUserId'] ?? '',
      productId: json['productId'] ?? 0,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      count: json['count'] ?? 1,
    );
  }
}

// ============================================================
// CART MODEL — full cart response
// ============================================================
class CartModel {
  final List<CartItemModel> items;
  final double totalPrice;

  const CartModel({required this.items, required this.totalPrice});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawCarts = json['carts'] as List<dynamic>? ?? [];
    return CartModel(
      items: rawCarts
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  static CartModel get empty => const CartModel(items: [], totalPrice: 0);
}

// ============================================================
// WEATHER MODEL — environmental metrics on dashboard
// ============================================================
class WeatherModel {
  final String location;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String airQuality;
  final String? icon;

  const WeatherModel({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.airQuality,
    this.icon,
  });

  static const WeatherModel demo = WeatherModel(
    location: 'Cairo, EG',
    temperature: 28.0,
    humidity: 64,
    windSpeed: 12.0,
    airQuality: 'Good',
  );

  /// Parses a Visual Crossing API response.
  /// https://weather.visualcrossing.com/.../timeline/{location}?unitGroup=metric&include=current
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current =
        json['currentConditions'] as Map<String, dynamic>? ?? {};

    // Capitalize each word of the resolved address, e.g. "cairo" → "Cairo, EG"
    final rawAddress = json['resolvedAddress'] as String? ?? 'Unknown';
    final location = rawAddress
        .split(',')
        .take(2)
        .map((part) => part
            .trim()
            .split(' ')
            .map((w) => w.isEmpty
                ? ''
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' '))
        .join(', ');

    final conditions = current['conditions'] as String? ?? 'Good';

    return WeatherModel(
      location: location.isEmpty ? 'Cairo, EG' : location,
      temperature: (current['temp'] ?? 0).toDouble(),
      humidity: (current['humidity'] ?? 0).toDouble().toInt(),
      windSpeed: (current['windspeed'] ?? 0).toDouble(),
      airQuality: conditions,
      icon: current['icon'] as String?,
    );
  }
}

// ============================================================
// TASK MODEL — today's schedule on dashboard
// ============================================================
class TaskModel {
  final String id;
  final String time;
  final String title;
  final String description;
  final bool isPriority;
  bool isDone;

  TaskModel({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    this.isPriority = false,
    this.isDone = false,
  });

  static List<TaskModel> get sampleTasks => [
        TaskModel(
          id: '1',
          time: '08:00 AM',
          title: 'Watering: Banana Row A',
          description: 'Check soil moisture before start.',
        ),
        TaskModel(
          id: '2',
          time: '11:30 AM',
          title: 'Fungicide Spray',
          description: 'As recommended for Corn Rust.',
          isPriority: true,
        ),
        TaskModel(
          id: '3',
          time: '04:00 PM',
          title: 'Check Greenhouse Vent',
          description: '',
        ),
      ];
}

// ============================================================
// RECENT SCAN MODEL — mini card on dashboard
// ============================================================
class RecentScanModel {
  final String plantName;
  final String plantType;
  final String imageUrl;
  final String timeAgo;
  final DiagnosisStatus status;
  final int confidencePercent;

  const RecentScanModel({
    required this.plantName,
    required this.plantType,
    required this.imageUrl,
    required this.timeAgo,
    required this.status,
    required this.confidencePercent,
  });

  static List<RecentScanModel> get sampleScans => [
        const RecentScanModel(
          plantName: 'Corn (....)',
          plantType: 'Corn Crop',
          imageUrl: 'https://zaraa-eta.vercel.app/images/corn-crop.png',
          timeAgo: '45m ago',
          status: DiagnosisStatus.infected,
          confidencePercent: 97,
        ),
        const RecentScanModel(
          plantName: 'Healthy Foliage',
          plantType: 'Banana Plant',
          imageUrl:
              'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=200',
          timeAgo: '2h ago',
          status: DiagnosisStatus.healthy,
          confidencePercent: 99,
        ),
      ];
}

// ============================================================
// ORDER STATUS ENUM
// ============================================================
enum OrderStatus {
  pending,
  processing,
  shipped,
  completed,
  canceled;

  static OrderStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'completed':
        return OrderStatus.completed;
      case 'canceled':
      case 'cancelled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }
}

// ============================================================
// ORDER ITEM MODEL
// ============================================================
class OrderItemModel {
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? json['name'] ?? 'Unknown Product',
      imageUrl: ApiConstants.imageUrl(json['mainImg'] ?? json['imageUrl']),
      quantity: json['quantity'] ?? json['count'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

// ============================================================
// ORDER MODEL
// ============================================================
class OrderModel {
  final int id;
  final OrderStatus status;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? address;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.status,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.address,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
  });

  String get formattedDate {
    final d = createdAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = d.hour > 12 ? d.hour - 12 : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month]} ${d.day}, ${d.year} at ${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['orderItems'] as List<dynamic>? ?? [];
    
    return OrderModel(
      id: json['id'] ?? json['orderId'] ?? 0,
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      customerName: json['customerName'] ?? json['userName'],
      customerEmail: json['customerEmail'] ?? json['email'],
      customerPhone: json['customerPhone'] ?? json['phoneNumber'],
      address: json['address'] ?? json['shippingAddress'],
      totalPrice: (json['totalPrice'] ?? json['total'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null || json['orderDate'] != null 
          ? DateTime.parse(json['createdAt'] ?? json['orderDate']) 
          : DateTime.now(),
      items: rawItems.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
