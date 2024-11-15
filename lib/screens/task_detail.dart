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

  // Função que atualiza o status de conclusão da tarefa
  Future<void> _toggleTaskCompletion() async {
    final newStatus = !(task['is_completed'] ?? false);
    final response = await _updateTaskStatus(newStatus);

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

  // Função para enviar o update da tarefa
  Future<http.Response> _updateTaskStatus(bool newStatus) {
    final taskId = task['id'];
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    return http.patch(
      Uri.parse(url),
      body: jsonEncode({'is_completed': newStatus}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Função para excluir a tarefa
  Future<void> _deleteTask() async {
    final response = await _deleteTaskFromApi();

    if (response.statusCode == 200) {
      _showSnackbar('Tarefa excluída com sucesso!', Colors.green);
      Navigator.pop(context, true);  // Retorna para a HomeScreen e sinaliza que houve alteração
    } else {
      _showSnackbar('Erro ao excluir tarefa!', Colors.red);
    }
  }

  // Função que deleta a tarefa no backend
  Future<http.Response> _deleteTaskFromApi() {
    final taskId = task['id'];
    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/$taskId.json';
    return http.delete(Uri.parse(url));
  }

  // Função para exibir a mensagem no snackbar
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Função para navegar para a tela de edição
  Future<void> _navigateToEditPage() async {
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

  // Função para formatar a data de vencimento
  String _formatDueDate(String? dueDate) {
    if (dueDate == null) return 'Não definida';
    
    try {
      DateTime parsedDate = DateTime.parse(dueDate);
      return DateFormat('dd/MM/yyyy').format(parsedDate);  // Formatar data
    } catch (e) {
      return 'Data inválida';
    }
  }

  // Função para confirmar a exclusão da tarefa
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
              _deleteTask();
              Navigator.of(context).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDueDate(task['due_date']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Tarefa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
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
                onPressed: _toggleTaskCompletion,
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
}
