import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../database/client_dao.dart';

class AddEditClientScreen extends StatefulWidget {
  final Client? client;

  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientDao = ClientDao();

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  late ClientType _selectedType;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.client != null) {
      // Режим редактирования
      _isEditMode = true;

      _nameController.text = widget.client!.name;
      _contactPersonController.text = widget.client!.contactPerson;
      _phoneController.text = widget.client!.phone;
      _emailController.text = widget.client!.email;
      _addressController.text = widget.client!.address;
      _websiteController.text = widget.client!.website ?? '';
      _notesController.text = widget.client!.notes ?? '';

      _selectedType = widget.client!.type;
    } else {
      // Режим создания нового клиента
      _selectedType = ClientType.company;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Client(
        id: _isEditMode ? widget.client!.id : '',
        name: _nameController.text,
        contactPerson: _contactPersonController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        type: _selectedType,
        website:
            _websiteController.text.isNotEmpty ? _websiteController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: _isEditMode ? widget.client!.createdAt : DateTime.now(),
        lastContactDate: _isEditMode ? widget.client!.lastContactDate : null,
      );

      if (_isEditMode) {
        await _clientDao.updateClient(client);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Клиент успешно обновлен'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _clientDao.createClient(client);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Клиент успешно создан'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Возвращаемся на предыдущий экран с результатом
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении клиента: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактирование клиента' : 'Новый клиент'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная информация о клиенте
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Название клиента
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название клиента';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Тип клиента
                      DropdownButtonFormField<ClientType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Тип клиента',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items:
                            ClientType.values.map((type) {
                              return DropdownMenuItem<ClientType>(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Контактная информация
                      const Text(
                        'Контактная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Контактное лицо
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Контактное лицо',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя контактного лица';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Телефон
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите номер телефона';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите email';
                          }
                          // Простая проверка формата email
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Адрес
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите адрес';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Веб-сайт (необязательно)
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Веб-сайт (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.web),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 24),

                      // Дополнительная информация
                      const Text(
                        'Дополнительная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Примечания
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Примечания',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Кнопка сохранения
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveClient,
                          child: Text(
                            _isEditMode
                                ? 'Сохранить изменения'
                                : 'Создать клиента',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
