
class Todo { 
  final int? id; 
  String title; 
  String description; 
  String priority; // 'low', 'medium', 'high'
  DateTime? dueDate;
  DateTime createdAt;
  bool isDone; 

  Todo({
    this.id, 
    required this.title, 
    this.description = '', 
    this.priority = 'medium',
    this.dueDate,
    DateTime? createdAt,
    this.isDone = false
  }) : createdAt = createdAt ?? DateTime.now(); 

  // แปลงเป็น Map สำหรับบันทึกลง SQLite 
  Map<String, dynamic> toMap() { 
    return { 
      'id': id, 
      'title': title, 
      'description': description,
      'priority': priority,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_done': isDone ? 1 : 0, 
    }; 
  } 

  // สร้างจาก Map ที่อ่านจาก SQLite 
  factory Todo.fromMap(Map<String, dynamic> map) { 
    return Todo( 
      id: map['id'] as int?, 
      title: map['title'] as String, 
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      isDone: (map['is_done'] as int) == 1, 
    ); 
  } 

  // คัดลอก Todo พร้อมแก้ไขบางฟิลด์
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    bool? isDone,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      isDone: isDone ?? this.isDone,
    );
  }

  // ตรวจสอบว่า todo หมดอายุหรือไม่
  bool get isOverdue {
    if (dueDate == null || isDone) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // ตรวจสอบว่า todo ใกล้หมดอายุหรือไม่ (ภายใน 1 วัน)
  bool get isDueSoon {
    if (dueDate == null || isDone) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference >= 0 && difference <= 1;
  }

  // รับสีตาม priority
  String get priorityColor {
    switch (priority) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      case 'low':
        return 'green';
      default:
        return 'blue';
    }
  }
}