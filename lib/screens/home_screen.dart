import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart'; 
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart'; 
import '../models/todo.dart'; 

class HomeScreen extends StatefulWidget { 
  const HomeScreen({super.key}); 

  @override 
  State<HomeScreen> createState() => _HomeScreenState(); 
} 

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _titleController = TextEditingController(); 
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // โหมดเลือกหลายรายการ 
  bool _selectionMode = false; 
  final Set<int> _selectedIds = {}; 

  @override 
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override 
  void dispose() { 
    _titleController.dispose(); 
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose(); 
  } 

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _showAddTodoDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTodoDialog(),
    );
    
    if (result != null) {
      await context.read<TodoProvider>().addTodo(
        result['title'] as String,
        description: result['description'] as String? ?? '',
        priority: result['priority'] as String? ?? 'medium',
        dueDate: result['dueDate'] as DateTime?,
      );
    }
  }

  Future<void> _showEditDialog(Todo todo) async { 
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditTodoDialog(todo: todo),
    );
    
    if (result != null) {
      await context.read<TodoProvider>().editTodo(
        todo,
        title: result['title'] as String?,
        description: result['description'] as String?,
        priority: result['priority'] as String?,
        dueDate: result['dueDate'] as DateTime?,
      );
    }
  } 

  void _enterSelectionMode([Todo? first]) { 
    setState(() { 
      _selectionMode = true; 
      _selectedIds.clear(); 
      if (first?.id != null) _selectedIds.add(first!.id!); 
    }); 
  } 

  void _exitSelectionMode() { 
    setState(() { 
      _selectionMode = false; 
      _selectedIds.clear(); 
    }); 
  } 

  void _toggleSelection(Todo todo) { 
    final id = todo.id; 
    if (id == null) return; 
    setState(() { 
      if (_selectedIds.contains(id)) { 
        _selectedIds.remove(id); 
      } else { 
        _selectedIds.add(id); 
      } 
      if (_selectedIds.isEmpty) { 
        _selectionMode = false; 
      } 
    }); 
  } 

  Future<void> _deleteSelected() async { 
    if (_selectedIds.isEmpty) return; 

    final provider = context.read<TodoProvider>(); 
    final count = _selectedIds.length; 

    final confirm = await showDialog<bool>( 
      context: context, 
      builder: (_) => AlertDialog( 
        title: const Text('ลบรายการที่เลือก?'), 
        content: Text('ต้องการลบ $count รายการที่เลือกหรือไม่'), 
        actions: [ 
          TextButton( 
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('ยกเลิก'), 
          ), 
          FilledButton( 
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ลบ'), 
          ), 
        ], 
      ), 
    ); 

    if (confirm == true) { 
      final items = List<Todo>.from(provider.items); 
      for (final t in items) { 
        if (t.id != null && _selectedIds.contains(t.id)) { 
          await provider.deleteTodo(t); 
        } 
      } 
      if (!mounted) return; 
      _exitSelectionMode(); 
    } 
  } 

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'สูง';
      case 'medium':
        return 'ปานกลาง';
      case 'low':
        return 'ต่ำ';
      default:
        return 'ไม่ระบุ';
    }
  }

  @override 
  Widget build(BuildContext context) { 
    final provider = context.watch<TodoProvider>(); 
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold( 
      backgroundColor: colorScheme.surface,
      appBar: AppBar( 
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        title: _selectionMode 
            ? Text('เลือกแล้ว ${_selectedIds.length} รายการ') 
            : const Text('งานของฉัน'), 
        leading: _selectionMode 
            ? IconButton( 
                tooltip: 'ยกเลิก', 
                icon: const Icon(Icons.close), 
                onPressed: _exitSelectionMode, 
              ) 
            : null, 
        actions: [ 
          if (_selectionMode) ...[ 
            IconButton( 
              tooltip: 'ลบที่เลือก', 
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected, 
              icon: const Icon(Icons.delete), 
            ), 
          ] else ...[ 
            IconButton( 
              tooltip: 'เลือกรายการ', 
              icon: const Icon(Icons.checklist), 
              onPressed: provider.items.isEmpty 
                  ? null 
                  : () => _enterSelectionMode(), 
            ), 
            PopupMenuButton<String>( 
              onSelected: (value) async { 
                final provider = context.read<TodoProvider>(); 
                 
                if (value == 'clear_all' && provider.items.isNotEmpty) { 
                  final confirm = await showDialog<bool>( 
                    context: context, 
                    builder: (_) => AlertDialog( 
                      title: const Text('ลบทั้งหมด?'), 
                      content: const Text('ต้องการลบงานทั้งหมดหรือไม่'), 
                      actions: [ 
                        TextButton( 
                          onPressed: () => Navigator.pop(context, false), 
                          child: const Text('ยกเลิก'), 
                        ), 
                        FilledButton( 
                          onPressed: () => Navigator.pop(context, true), 
                          child: const Text('ลบทั้งหมด'), 
                        ), 
                      ], 
                    ), 
                  ); 
                  if (confirm == true) { 
                    if (!mounted) return; 
                    await provider.clearAll(); 
                  } 
                } 
              }, 
              itemBuilder: (_) => [ 
                const PopupMenuItem( 
                  value: 'clear_all', 
                  child: Text('ลบทั้งหมด'), 
                ), 
              ], 
            ), 
          ], 
        ], 
      ), 
      body: Column( 
        children: [ 
          // Add Todo Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'เพิ่มงานใหม่...',
                              prefixIcon: Icon(Icons.add_task),
                            ),
                            onSubmitted: (_) => _addTodo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _addTodo,
                          icon: const Icon(Icons.add),
                          label: const Text('เพิ่ม'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _showAddTodoDialog,
                          icon: const Icon(Icons.edit_note),
                          label: const Text('เพิ่มรายละเอียด'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _toggleExpanded,
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                          label: Text(_isExpanded ? 'ซ่อน' : 'แสดงเพิ่มเติม'),
                        ),
                      ],
                    ),
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: Column(
                        children: [
                          const Divider(),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'รายละเอียดงาน...',
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedPriority,
                                  decoration: const InputDecoration(
                                    labelText: 'ความสำคัญ',
                                    prefixIcon: Icon(Icons.priority_high),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'low', child: Text('ต่ำ')),
                                    DropdownMenuItem(value: 'medium', child: Text('ปานกลาง')),
                                    DropdownMenuItem(value: 'high', child: Text('สูง')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPriority = value ?? 'medium';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectDueDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'วันที่ครบกำหนด',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _selectedDueDate != null
                                          ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                                          : 'เลือกวันที่',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Todo List
          Expanded( 
            child: provider.isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : provider.items.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ยังไม่มีงาน',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ใส่ชื่องานด้านบนแล้วกด "เพิ่ม"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ) 
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.items.length, 
                    separatorBuilder: (_, __) => const SizedBox(height: 8), 
                    itemBuilder: (context, index) { 
                      final todo = provider.items[index]; 
                      final id = todo.id; 
                      final selected = id != null && _selectedIds.contains(id); 

                      return _buildTodoCard(todo, selected, theme, colorScheme);
                    }, 
                  ), 
          ), 
        ], 
      ), 
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มงาน'),
      ),
    ); 
  }

  Widget _buildTodoCard(Todo todo, bool selected, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: selected ? 8 : 2,
      color: selected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(todo);
          } else {
            context.read<TodoProvider>().toggleDone(todo);
          }
        },
        onLongPress: () => _enterSelectionMode(todo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_selectionMode) ...[
                Checkbox(
                  value: selected,
                  onChanged: (_) => _toggleSelection(todo),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Checkbox(
                  value: todo.isDone,
                  onChanged: (_) => context.read<TodoProvider>().toggleDone(todo),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            todo.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: todo.isDone ? TextDecoration.lineThrough : null,
                              color: todo.isDone ? colorScheme.outline : null,
                              fontWeight: selected ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                        if (todo.priority != 'medium')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(todo.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getPriorityColor(todo.priority).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getPriorityText(todo.priority),
                              style: TextStyle(
                                color: _getPriorityColor(todo.priority),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (todo.dueDate != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: todo.isOverdue 
                                ? Colors.red 
                                : todo.isDueSoon 
                                    ? Colors.orange 
                                    : colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(todo.dueDate!),
                            style: TextStyle(
                              color: todo.isOverdue 
                                  ? Colors.red 
                                  : todo.isDueSoon 
                                      ? Colors.orange 
                                      : colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(todo.createdAt),
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_selectionMode) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(todo),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _addTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descriptionController.text.trim();
    final dueDate = _selectedDueDate;

    await context.read<TodoProvider>().addTodo(
      title,
      description: description,
      priority: _selectedPriority,
      dueDate: dueDate,
    );

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedPriority = 'medium';
      _selectedDueDate = null;
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }
}

class AddTodoDialog extends StatefulWidget {
  @override
  _AddTodoDialogState createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มงานใหม่'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่องาน',
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'ความสำคัญ',
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('ต่ำ')),
                      DropdownMenuItem(value: 'medium', child: Text('ปานกลาง')),
                      DropdownMenuItem(value: 'high', child: Text('สูง')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value ?? 'medium';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'วันที่ครบกำหนด',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                            : 'เลือกวันที่',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'priority': _selectedPriority,
                'dueDate': _selectedDueDate,
              });
            }
          },
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }
}

class EditTodoDialog extends StatefulWidget {
  final Todo todo;

  const EditTodoDialog({super.key, required this.todo});

  @override
  _EditTodoDialogState createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
    _selectedPriority = widget.todo.priority;
    _selectedDueDate = widget.todo.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขงาน'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่องาน',
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'ความสำคัญ',
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('ต่ำ')),
                      DropdownMenuItem(value: 'medium', child: Text('ปานกลาง')),
                      DropdownMenuItem(value: 'high', child: Text('สูง')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value ?? 'medium';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'วันที่ครบกำหนด',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                            : 'เลือกวันที่',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim(),
                'priority': _selectedPriority,
                'dueDate': _selectedDueDate,
              });
            }
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }
}