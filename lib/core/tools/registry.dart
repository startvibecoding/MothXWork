abstract class DeveloperTool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;

  Future<String> execute(String cwd, Map<String, dynamic> arguments);
}

class ToolRegistry {
  final Map<String, DeveloperTool> _tools = {};

  void register(DeveloperTool tool) {
    _tools[tool.name] = tool;
  }

  DeveloperTool? get(String name) => _tools[name];

  List<Map<String, dynamic>> getDefinitions() {
    return _tools.values.map((t) => {
      'name': t.name,
      'description': t.description,
      'parameters': t.parameters,
    }).toList();
  }
}
