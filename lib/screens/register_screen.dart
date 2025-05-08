import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Залиште, якщо використовуєте UserProvider деінде
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  // Видалено: final _userTypeController = TextEditingController(); // Більше не потрібен для Dropdown

  // Додано: Змінна стану для обраного типу користувача
  String? _selectedUserType;
  // Додано: Список доступних типів користувачів
  final List<String> _userTypes = [
    'Buyer',
    'Seller',
  ]; // Типи, які очікує бек-енд

  // Додано: Ключ для валідації форми
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Очистка контролерів
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    // Видалено: _userTypeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Валідуємо форму перед надсиланням
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;
      final email = _emailController.text;
      // Використовуємо обране значення зі змінної стану
      final userType =
          _selectedUserType!; // Не буде null, якщо валідація пройшла

      // Опціонально: Показати індикатор завантаження
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Реєстрація...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        // Припускаємо, що AuthService().register приймає username, password, email, userType (рядок)
        final response = await AuthService().register(
          username,
          password,
          email,
          userType, // Надсилаємо обраний рядок типу користувача
        );

        // Обробка успішної реєстрації
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Реєстрація успішна! Перенаправлення...'),
          ),
        );
        // Перенаправляємо на екран логіна (або головний екран, якщо реєстрація автоматично логінить)
        // Використовуємо pushReplacementNamed, щоб користувач не міг повернутися назад на реєстрацію
        Navigator.pushReplacementNamed(
          context,
          '/login',
        ); // Припускаємо, що '/login' - це маршрут до екрану логіна
        // Або якщо після реєстрації користувач автоматично логіниться, можна перейти на головний екран:
        // Navigator.pushReplacementNamed(context, '/');
      } catch (error) {
        // Показати повідомлення про помилку, якщо реєстрація не вдалася
        // Припускаємо, що об'єкт помилки має зрозуміле повідомлення
        String errorMessage = 'Помилка реєстрації.';
        // Спробуємо витягнути повідомлення з помилки, якщо це Exception
        if (error.toString().contains('Exception: ')) {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage =
              error.toString(); // Використовуємо рядок з помилки як є
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка реєстрації: $errorMessage')),
        );
        print(
          'Помилка реєстрації (детально): $error',
        ); // Логуємо повну помилку для відладки
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реєстрація'),
      ), // Назва AppBar українською
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          // Центруємо вміст по вертикалі (якщо місця достатньо)
          child: SingleChildScrollView(
            // Додаємо SingleChildScrollView, щоб запобігти переповненню на маленьких екранах
            child: Form(
              // Використовуємо Form для зручної валідації
              key: _formKey, // Призначаємо ключ форми
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Центруємо вміст колонки
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch, // Розтягуємо елементи по горизонталі
                children: <Widget>[
                  Text(
                    // Додаємо заголовок форми
                    'Створити новий обліковий запис',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleLarge, // Використовуємо стиль заголовка
                  ),
                  const SizedBox(height: 24), // Відступ

                  TextFormField(
                    // Використовуємо TextFormField для інтеграції з Form
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Ім\'я користувача',
                    ), // Назва поля українською
                    validator: (value) {
                      // Додаємо валідацію
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть ім\'я користувача';
                      }
                      // Додаткова валідація (наприклад, мінімальна довжина)
                      return null; // Повертаємо null, якщо валідно
                    },
                  ),
                  const SizedBox(height: 16), // Відступ

                  TextFormField(
                    // Використовуємо TextFormField
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                    ), // Назва поля українською
                    obscureText: true, // Приховуємо текст пароля
                    validator: (value) {
                      // Додаємо валідацію
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть пароль';
                      }
                      // Додаткова валідація складності пароля
                      return null;
                    },
                  ),
                  const SizedBox(height: 16), // Відступ

                  TextFormField(
                    // Використовуємо TextFormField
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ), // Назва поля українською
                    keyboardType:
                        TextInputType
                            .emailAddress, // Пропонуємо клавіатуру для email
                    validator: (value) {
                      // Додаємо валідацію
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть email';
                      }
                      // Додаткова валідація формату email
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Будь ласка, введіть коректний email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16), // Відступ
                  // === ЗАМІНА TextField на DropdownButtonFormField ===
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      // Оформлення DropdownButtonFormField
                      labelText: 'Тип користувача', // Назва поля українською
                      border: OutlineInputBorder(
                        // Додаємо рамку
                        borderRadius: BorderRadius.circular(
                          5.0,
                        ), // Можна налаштувати
                      ),
                      filled: true, // Заливка поля (як у TextField)
                      fillColor:
                          Colors.grey[200], // Колір заливки (опціонально)
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 15.0,
                      ), // Налаштування внутрішніх відступів
                    ),
                    value:
                        _selectedUserType, // Зв'язуємо значення з змінною стану
                    hint: const Text(
                      'Оберіть тип користувача',
                    ), // Текст-підказка, коли нічого не обрано
                    items:
                        _userTypes.map((String type) {
                          // Створюємо DropdownMenuItem для кожного типу
                          return DropdownMenuItem<String>(
                            value:
                                type, // Значення елемента (наприклад, "Buyer")
                            child: Text(
                              type,
                            ), // Текст, що відображається в списку
                          );
                        }).toList(), // Перетворюємо мап у список
                    onChanged: (String? newValue) {
                      // Обробник зміни обраного значення
                      setState(() {
                        _selectedUserType =
                            newValue; // Оновлюємо змінну стану при виборі
                      });
                    },
                    validator: (value) {
                      // Додаємо валідацію для обов'язкового вибору
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, оберіть тип користувача'; // Повідомлення, якщо нічого не обрано
                      }
                      return null; // Повертаємо null, якщо щось обрано
                    },
                  ),
                  const SizedBox(height: 24), // Відступ

                  ElevatedButton(
                    onPressed:
                        _register, // Призначаємо метод _register на кнопку
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ), // Налаштування відступів кнопки
                    ),
                    child: const Text(
                      'Зареєструватися',
                    ), // Текст кнопки українською
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
