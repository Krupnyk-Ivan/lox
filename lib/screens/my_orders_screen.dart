import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/advertisement_service.dart';
import '../services/user_provider.dart';

class MyOrdersScreen extends StatefulWidget {
  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    print(currentUser?.userType);
    if (currentUser != null && currentUser.id != null) {
      setState(() {
        // Check if the current user is a buyer or seller
        if (currentUser.userType == 'Buyer') {
          // Fetch orders where the current user is the buyer
          _orders = AdvertisementService().getOrders(currentUser.id!);
        } else if (currentUser.userType == 'Seller') {
          print(currentUser.id);
          _orders = AdvertisementService().getOrdersBySeller(currentUser.id!);
        } else {
          // Handle case if the role is undefined or not found
          _orders = Future.value([]);
        }
      });
    }
  }

  // Handle order action (Cancel/Confirm)
  Future<void> _handleOrderAction(Order order, String action) async {
    try {
      if (action == 'cancel') {
        await AdvertisementService().cancelOrder(order.id!); // Cancel the order
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Замовлення скасовано')));
      } else if (action == 'confirm') {
        await AdvertisementService().confirmOrder(
          order.id!,
        ); // Confirm the order
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Замовлення підтверджено')));
      }

      // Reload orders after action
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${e.toString()}')));
    }
  }

  void _showFeedbackDialog(Order order) {
    final TextEditingController commentController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Залишити відгук'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: 'Коментар'),
                maxLines: 3,
              ),
              DropdownButton<int>(
                value: rating,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => rating = value);
                  }
                },
                items:
                    [1, 2, 3, 4, 5].map((e) {
                      return DropdownMenuItem(value: e, child: Text('$e ★'));
                    }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Скасувати'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Зберегти'),
              onPressed: () async {
                try {
                  final user =
                      Provider.of<UserProvider>(context, listen: false).user!;
                  await AdvertisementService().addFeedback(
                    order.advertisementId!,
                    user.id!,
                    commentController.text,
                    rating,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Відгук додано')));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Мої замовлення")),
      body: FutureBuilder<List<Order>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Помилка при завантаженні замовлень'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(child: Text('У вас немає замовлень.'));
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                // Determine if the current user is the buyer or seller
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                final currentUser = userProvider.user;

                // Check if the current user is the buyer or seller
                final isBuyer = currentUser?.id == order.buyerId;
                final isSeller = currentUser?.id == order.sellerId;

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Замовлення ID: ${order.id}'),
                        Text('Статус: ${order.orderStatus}'),
                        Text('Ціна: ${order.finalPrice}'),
                        if (isSeller && order.orderStatus == 'Pending')
                          TextButton(
                            onPressed:
                                () => _handleOrderAction(order, 'cancel'),
                            child: Text(
                              'Відмінити замовлення',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        if (isBuyer && order.orderStatus == 'confirmed')
                          TextButton(
                            onPressed: () => _showFeedbackDialog(order),
                            child: Text(
                              'Залишити відгук',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),

                        if (isBuyer && order.orderStatus == 'Pending')
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      () =>
                                          _handleOrderAction(order, 'confirm'),
                                  child: Text(
                                    'Підтвердити замовлення',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      () => _handleOrderAction(order, 'cancel'),
                                  child: Text(
                                    'Відмінити замовлення',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    onTap: () {
                      // Optionally navigate to a detailed order screen
                    },
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('Немає замовлень для відображення.'));
          }
        },
      ),
    );
  }
}
