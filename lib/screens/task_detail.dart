import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importando o pacote intl
import 'add_page.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Map<String, dynamic> task;
  
  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  Future<void> toggleTaskCompletion() async {
    final taskId = task['id'];
    final newStatus = !(task['is_completed'] ?? false);
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final response = await http.patch(
      Uri.parse(url),
      body: jsonEncode({'is_completed': newStatus}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        task['is_completed'] = newStatus;
      });
      _showSnackbar(newStatus ? 'Tarefa concluída!' : 'Tarefa marcada como pendente!', Colors.purpleAccent);
      Navigator.pop(context, true);  // Retorna para a HomeScreen e sinaliza que houve alteração
    } else {
      _showSnackbar('Erro ao atualizar status da tarefa!', Colors.red);
    }
  }

  Future<void> deleteTask() async {
    final taskId = task['id'];
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      _showSnackbar('Tarefa excluída com sucesso!', Colors.green);
      Navigator.pop(context, true);  // Retorna para a HomeScreen e sinaliza que houve alteração
    } else {
      _showSnackbar('Erro ao excluir tarefa!', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> navigateToEditPage() async {
    final updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPage(task: task), 
      ),
    );

    if (updatedTask != null) {
      setState(() {
        task = updatedTask;
      });
      Navigator.pop(context, true);  // Retorna para HomeScreen após edição bem-sucedida
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatar a data de vencimento no formato dd/MM/yyyy
    String formattedDate = '';
    if (task['due_date'] != null) {
      try {
        DateTime dueDate = DateTime.parse(task['due_date']);
        formattedDate = DateFormat('dd/MM/yyyy').format(dueDate);  // Formatar data
      } catch (e) {
        formattedDate = 'Data inválida';
      }
    } else {
      formattedDate = 'Não definida';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Tarefa'), centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: navigateToEditPage,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black87,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['title'] ?? 'Sem título',
              style: const TextStyle(fontSize: 24, color: Colors.purpleAccent),
            ),
            const SizedBox(height: 10),
            Text(
              'Categoria: ${task['category'] ?? 'Sem categoria'}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Descrição: ${task['description'] ?? 'Sem descrição'}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Data de Vencimento: $formattedDate',  // Exibindo a data formatada
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: toggleTaskCompletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: task['is_completed'] == true
                      ? Colors.orange
                      : Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  task['is_completed'] == true
                      ? 'Marcar como Pendente'
                      : 'Marcar como Concluída',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza de que deseja excluir esta tarefa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              deleteTask();
              Navigator.of(context).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
