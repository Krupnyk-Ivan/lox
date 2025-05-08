// screens/advertisement_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../models/order.dart';
import '../screens/edit_advertisement_screen.dart';

import '../models/feedback.dart';

class AdvertisementDetailScreen extends StatefulWidget {
  final int
  advertisementId; // Передаватимемо тільки ID для завантаження повних даних

  const AdvertisementDetailScreen({required this.advertisementId, super.key});

  @override
  State<AdvertisementDetailScreen> createState() =>
      _AdvertisementDetailScreenState();
}

class _AdvertisementDetailScreenState extends State<AdvertisementDetailScreen> {
  late Future<Advertisement> _futureAdvertisement;
  String _categoryName = 'Loading...';
  String _regionName = 'Loading...';
  bool _isCreatingOrder = false;
  late Future<List<FeedbackModel>> _futureFeedbacks;

  @override
  void initState() {
    super.initState();
    _futureAdvertisement =
        _fetchAdvertisementDetails(); // Завантажуємо деталі при ініціалізації
    _futureFeedbacks = AdvertisementService().fetchFeedbacks(
      widget.advertisementId,
    );
  }

  Future<Advertisement> _fetchAdvertisementDetails() async {
    try {
      final ad = await AdvertisementService().fetchAdvertisement(
        widget.advertisementId,
      );
      // Окремо завантажуємо назви категорії та регіону після завантаження оголошення
      if (ad.categoryId != null) {
        _categoryName = await AdvertisementService().fetchCategoryNameById(
          ad.categoryId!,
        );
      }
      if (ad.regionId != null) {
        _regionName = await AdvertisementService().fetchRegionNameById(
          ad.regionId!,
        );
      }
      setState(() {}); // Оновлюємо UI після завантаження назв
      return ad;
    } catch (e) {
      print('Error fetching advertisement details: $e'); // Логування помилки
      rethrow; // Перекидаємо помилку далі
    }
  }

  void _createOrder(Advertisement ad) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, увійдіть, щоб здійснити покупку.'),
        ),
      );
      return;
    }

    if (ad.sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Помилка: Продавець оголошення не визначено.'),
        ),
      );
      return;
    }

    final orderData = Order(
      advertisementId: ad.id!,
      buyerId: currentUser.id!,
      sellerId: ad.sellerId!,
      finalPrice: ad.price,
      orderStatus: 'Pending',
      // No need to manually set the orderStatus, it defaults to 'Pending' in the Order class
    );

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      final createdOrder = await AdvertisementService().createOrder(orderData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Замовлення успішно створено! ID: ${createdOrder.id}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка створення замовлення: ${e.toString()}'),
        ),
      );
      print('Error creating order: $e');
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Деталі оголошення')),
      body: FutureBuilder<Advertisement>(
        future: _futureAdvertisement,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Помилка завантаження: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Оголошення не знайдено.'));
          }

          final ad = snapshot.data!;

          return SingleChildScrollView(
            // Дозволяє прокручувати вміст
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Зображення оголошення
                ad.imageBase64 != null && ad.imageBase64!.isNotEmpty
                    ? Center(
                      // Центруємо зображення
                      child: Image.memory(
                        base64Decode(ad.imageBase64!),
                        fit:
                            BoxFit
                                .contain, // Зображення вміщається без обрізання
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 150,
                            ), // Обробка помилки завантаження зображення
                      ),
                    )
                    : const Center(
                      child: Icon(Icons.image_not_supported, size: 150),
                    ), // Заглушка, якщо зображення немає

                const SizedBox(height: 20),

                // Заголовок
                Text(
                  ad.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Ціна
                Text(
                  'Ціна: ${ad.price.toStringAsFixed(2)} UAH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700], // Або інший колір для ціни
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Категорія та Регіон (використовуємо окремо завантажені назви)
                Row(
                  children: [
                    Icon(Icons.category, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Expanded(
                      // <--- Обгортаємо Text в Expanded
                      child: Text(
                        'Категорія: $_categoryName',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow:
                            TextOverflow
                                .ellipsis, // Додаємо, якщо хочете "..." замість переповнення
                        maxLines:
                            1, // Обмежуємо одним рядком перед обрізанням, якщо потрібно
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      // <--- Обгортаємо Text в Expanded
                      child: Text(
                        'Регіон: $_regionName',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow:
                            TextOverflow.ellipsis, // Додаємо, якщо хочете "..."
                        maxLines: 1, // Обмежуємо одним рядком, якщо потрібно
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Дата створення (якщо є)
                if (ad.createdDate != null)
                  Text(
                    'Опубліковано: ${ad.createdDate!.toLocal().toString().split(' ')[0]}', // Форматуємо дату
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 10),

                // Опис
                Text(
                  'Опис:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                if (currentUser?.id == ad.sellerId)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Редагувати'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditAdvertisementScreen(
                                  advertisementId: ad.id,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                // Кнопка "Купити"
                if (currentUser?.id !=
                    ad.sellerId) // Не показуємо кнопку, якщо це власне оголошення
                  Center(
                    child:
                        _isCreatingOrder
                            ? const CircularProgressIndicator() // Індикатор завантаження
                            : ElevatedButton(
                              onPressed:
                                  () => _createOrder(
                                    ad,
                                  ), // Викликаємо метод створення замовлення
                              child: const Text('Купити'),
                            ),
                  ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Text(
                  'Відгуки:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<FeedbackModel>>(
                  future: _futureFeedbacks,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text(
                        'Помилка завантаження відгуків: ${snapshot.error}',
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Ще немає відгуків.');
                    }

                    final feedbacks = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final feedback = feedbacks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.comment),
                            title: Text(feedback.commentText.toString()),
                            subtitle: Text(
                              'Дата: ${feedback.createdDate}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
