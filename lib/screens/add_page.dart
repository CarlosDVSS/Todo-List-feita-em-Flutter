import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddPage extends StatefulWidget {
  final Map<String, dynamic>? task;

  const AddPage({super.key, this.task});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;
  bool titleError = false;
  bool categoryError = false;
  bool descriptionError = false;
  bool dateError = false;
  bool isLoading = false; // Adicionando a variável de carregamento

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleController.text = widget.task!['title'] ?? '';
      categoryController.text = widget.task!['category'] ?? '';
      descriptionController.text = widget.task!['description'] ?? '';
      selectedDate = DateTime.tryParse(widget.task!['due_date'] ?? '');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? "Nova Tarefa" : "Editar Tarefa"),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Adicionando o SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading) // Exibe o carregamento se estiver em progresso
                const Center(child: CircularProgressIndicator()),
              if (!isLoading) ...[
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: titleError ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: titleError ? Colors.red : Colors.purpleAccent,
                      ),
                    ),
                    hintText: 'Insira o título da tarefa',
                    errorText: titleError ? 'O título é obrigatório' : null,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: categoryError ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: categoryError ? Colors.red : Colors.purpleAccent,
                      ),
                    ),
                    hintText: 'Insira a categoria da tarefa',
                    errorText: categoryError ? 'A categoria é obrigatória' : null,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: descriptionError ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: descriptionError ? Colors.red : Colors.purpleAccent,
                      ),
                    ),
                    hintText: 'Comece a escrever...',
                    errorText: descriptionError ? 'A descrição é obrigatória' : null,
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 8,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      selectedDate == null
                          ? 'Data: Não selecionada'
                          : 'Data: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: dateError ? Colors.red : Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Escolher Data'),
                    ),
                  ],
                ),
                if (dateError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'A data de vencimento é obrigatória',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.purpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      widget.task == null ? 'Criar Tarefa' : 'Atualizar Tarefa',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black87,
    );
  }

  void validateAndSubmit() {
    setState(() {
      titleError = titleController.text.isEmpty;
      categoryError = categoryController.text.isEmpty;
      descriptionError = descriptionController.text.isEmpty;
      dateError = selectedDate == null;
    });

    if (!titleError && !categoryError && !descriptionError && !dateError) {
      setState(() {
        isLoading = true; // Ativa o carregamento
      });
      if (widget.task == null) {
        createTask();
      } else {
        updateTask();
      }
    } else {
      _showSnackbar('Todos os campos são obrigatórios!', Colors.redAccent);
    }
  }

  Future<void> createTask() async {
    final body = {
      "title": titleController.text,
      "category": categoryController.text,
      "description": descriptionController.text,
      "is_completed": false,
      "due_date": "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
    };

    const url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks.json';
    final response = await http.post(Uri.parse(url), body: jsonEncode(body));

    setState(() {
      isLoading = false; // Desativa o carregamento
    });

    if (response.statusCode == 200) {
      _showSnackbar('Tarefa criada com sucesso!', Colors.green);
      Navigator.pop(context, true); // Passa a tarefa criada de volta para a HomeScreen.
    } else {
      _showSnackbar('Erro ao criar tarefa!', Colors.red);
    }
  }

  Future<void> updateTask() async {
    final body = {
      "title": titleController.text,
      "category": categoryController.text,
      "description": descriptionController.text,
      "is_completed": widget.task!['is_completed'] ?? false,
      "due_date": "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
    };

    final url = 'https://todo-list-d016d-default-rtdb.firebaseio.com/tasks/${widget.task!['id']}.json';
    final response = await http.patch(Uri.parse(url), body: jsonEncode(body));

    setState(() {
      isLoading = false; // Desativa o carregamento
    });

    if (response.statusCode == 200) {
      _showSnackbar('Tarefa atualizada com sucesso!', Colors.green);
      Navigator.pop(context, jsonDecode(response.body));
    } else {
      _showSnackbar('Erro ao atualizar tarefa!', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }
}
