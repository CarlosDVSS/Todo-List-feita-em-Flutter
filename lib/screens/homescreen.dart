import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:todo_app/screens/add_page.dart';
import 'package:http/http.dart' as http;
import 'package:todo_app/screens/task_detail.dart';
import 'package:intl/intl.dart';

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  List<Map<String, dynamic>> items = [];
  List<String> categories = [];
  String? selectedFilter;
  String? selectedCategory;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Tarefas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          _buildFilterMenu(),
        ],
      ),
      body: Stack(
        children: [
          _buildTaskList(),
          if (isLoading) _buildLoadingIndicator(),
        ],
      ),
      floatingActionButton: _buildAddButton(),
      backgroundColor: Colors.black87,
    );
  }

  PopupMenuButton<String> _buildFilterMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          selectedFilter = value;
          if (value == 'category') {
            _showCategoryFilterDialog();
          } else {
            fetchTodo();
          }
        });
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(value: 'date', child: Text('Filtrar por Data')),
          const PopupMenuItem(value: 'category', child: Text('Filtrar por Categoria')),
          const PopupMenuItem(value: 'none', child: Text('Remover Filtro')),
        ];
      },
    );
  }

  Widget _buildTaskList() {
    return items.isEmpty
        ? const Center(
            child: Text(
              'Nenhuma tarefa encontrada.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        : ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _buildTaskCard(items[index]),
          );
  }

  Widget _buildTaskCard(Map<String, dynamic> item) {
    final dueDate = DateTime.tryParse(item['due_date'] ?? '');
    final daysLeft = dueDate?.difference(DateTime.now()).inDays;
    final dueDateColor = _getDueDateColor(daysLeft);
    final formattedDate = dueDate != null
        ? DateFormat('dd/MM/yyyy').format(dueDate)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: item['is_completed'] == true
              ? const BorderSide(color: Colors.green, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            if (item['is_completed'] == true)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                item['title'] ?? 'Sem título',
                style: TextStyle(
                  fontSize: 18,
                  color: item['is_completed'] == true
                      ? Colors.white54
                      : Colors.purpleAccent,
                  decoration: item['is_completed'] == true
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['category'] ?? 'Sem categoria',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data de vencimento: $formattedDate',
                    style: TextStyle(color: dueDateColor),
                  ),
                ],
              ),
              trailing: _buildTaskActionButtons(item),
              onTap: () async {
                final refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: item),
                  ),
                );
                if (refresh == true) {
                  fetchTodo();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Row _buildTaskActionButtons(Map<String, dynamic> item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            item['is_completed'] == true
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: item['is_completed'] == true
                ? Colors.green
                : Colors.purpleAccent,
          ),
          onPressed: () => toggleTaskCompletion(item),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmationDialog(item['id']),
        ),
      ],
    );
  }

  Color _getDueDateColor(int? daysLeft) {
    if (daysLeft == null) {
      return Colors.white70;
    }
    if (daysLeft <= 5) {
      return Colors.red;
    } else if (daysLeft <= 14) {
      return Colors.amber;
    }
    return Colors.green;
  }

  Center _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.purpleAccent,
      ),
    );
  }

  FloatingActionButton _buildAddButton() {
    return FloatingActionButton(
      onPressed: () async {
        setState(() {
          isLoading = true;
        });
        final refresh = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPage()),
        );
        if (refresh == true) {
          fetchTodo();
        }
        setState(() {
          isLoading = false;
        });
      },
      backgroundColor: Colors.purpleAccent,
      child: const Icon(Icons.add),
    );
  }

  Future<void> fetchTodo() async {
    setState(() {
      isLoading = true;
    });

    const url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks.json';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      final List<Map<String, dynamic>> result = [];
      final Set<String> categorySet = {};

      json.forEach((key, value) {
        final task = {
          'id': key,
          'title': value['title'],
          'category': value['category'],
          'description': value['description'],
          'due_date': value['due_date'],
          'is_completed': value['is_completed'],
        };

        result.add(task);
        categorySet.add(value['category']);
      });

      // Aplicando filtros
      if (selectedFilter == 'category' && selectedCategory != null) {
        result.retainWhere((task) => task['category'] == selectedCategory);
      } else if (selectedFilter == 'date') {
        result.sort((a, b) {
          final dateA = DateTime.tryParse(a['due_date'] ?? '');
          final dateB = DateTime.tryParse(b['due_date'] ?? '');
          return dateA?.compareTo(dateB ?? DateTime.now()) ?? 0;
        });
      }

      setState(() {
        items = result;
        categories = categorySet.toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao buscar dados!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> toggleTaskCompletion(Map<String, dynamic> task) async {
    setState(() {
      isLoading = true;
    });

    final taskId = task['id'];
    final newStatus = !(task['is_completed'] ?? false);
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final uri = Uri.parse(url);
    final response = await http.patch(uri, body: jsonEncode({'is_completed': newStatus}));

    if (response.statusCode == 200) {
      fetchTodo();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar tarefa!')),
      );
    }
  }

  Future<void> _showCategoryFilterDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolha a Categoria'),
          content: SingleChildScrollView(
            child: Column(
              children: categories.map((category) {
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.of(context).pop(category);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        selectedCategory = selected;
      });
      fetchTodo();
    }
  }

  Future<void> _showDeleteConfirmationDialog(String taskId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Tarefa'),
          content: const Text('Tem certeza de que deseja excluir esta tarefa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await deleteTask(taskId);
    }
  }

  Future<void> deleteTask(String taskId) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      fetchTodo();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir tarefa!')),
      );
    }
  }
}
