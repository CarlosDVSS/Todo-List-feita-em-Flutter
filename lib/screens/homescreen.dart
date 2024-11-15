import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:todo_app/screens/add_page.dart';
import 'package:http/http.dart' as http;
import 'package:todo_app/screens/task_detail.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  List items = [];
  List<String> categories = [];
  String? selectedFilter;
  String? selectedCategory;
  bool isLoading = false; // Adicionando controle de carregamento

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
          PopupMenuButton<String>(
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
          ),
        ],
      ),
      body: Stack(
        children: [
          items.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma tarefa encontrada.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final dueDate = DateTime.tryParse(item['due_date'] ?? '');
                    final daysLeft = dueDate?.difference(DateTime.now()).inDays;

                    Color dueDateColor;
                    if (daysLeft != null) {
                      if (daysLeft <= 5) {
                        dueDateColor = Colors.red;
                      } else if (daysLeft <= 14) {
                        dueDateColor = Colors.amber;
                      } else {
                        dueDateColor = Colors.green;
                      }
                    } else {
                      dueDateColor = Colors.white70;
                    }

                    // Formatar a data no formato dd/MM/yyyy
                    String formattedDate = '';
                    if (dueDate != null) {
                      formattedDate = DateFormat('dd/MM/yyyy').format(dueDate);
                    }

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
                                    'Data de vencimento: $formattedDate', // Exibindo a data formatada
                                    style: TextStyle(color: dueDateColor),
                                  ),
                                ],
                              ),
                              trailing: Row(
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
                                    onPressed: () {
                                      toggleTaskCompletion(item);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(item['id']);
                                    },
                                  ),
                                ],
                              ),
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
                  },
                ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            ), // Adicionando o indicador de carregamento
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            isLoading = true; // Ativa o carregamento antes de navegar
          });
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPage()),
          );
          if (refresh == true) {
            fetchTodo();
          }
          setState(() {
            isLoading = false; // Desativa o carregamento após a navegação
          });
        },
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.black87,
    );
  }

  Future<void> fetchTodo() async {
    setState(() {
      isLoading = true; // Ativa o carregamento antes da requisição
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
        isLoading = false; // Desativa o carregamento após a requisição
      });
    } else {
      setState(() {
        isLoading = false; // Desativa o carregamento em caso de erro
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
      isLoading = true; // Ativa o carregamento durante a atualização
    });

    final taskId = task['id'];
    final newStatus = !(task['is_completed'] ?? false);
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final uri = Uri.parse(url);
    final response = await http.patch(uri, body: jsonEncode({'is_completed': newStatus}));

    if (response.statusCode == 200) {
      fetchTodo(); // Recarrega as tarefas após a atualização
    } else {
      setState(() {
        isLoading = false; // Desativa o carregamento em caso de erro
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar tarefa!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(String taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza de que deseja excluir esta tarefa?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTask(taskId);
                Navigator.pop(context);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    setState(() {
      isLoading = true; // Ativa o carregamento durante a exclusão
    });

    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      fetchTodo(); // Recarrega as tarefas após a exclusão
    } else {
      setState(() {
        isLoading = false; // Desativa o carregamento em caso de erro
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao excluir tarefa!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar por Categoria'),
          content: DropdownButton<String>(
            value: selectedCategory,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue;
              });
              Navigator.pop(context);
              fetchTodo();
            },
            items: categories
                .map<DropdownMenuItem<String>>(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
