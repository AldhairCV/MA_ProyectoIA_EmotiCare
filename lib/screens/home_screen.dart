import 'package:flutter/material.dart';
import 'package:proyecto_flutter_ia/widgets/data_loader.dart';
import 'package:proyecto_flutter_ia/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<List<dynamic>>? _data;
  List<List<dynamic>>? _filteredData;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedFilter = "Todos";
  List<String> _filterOptions = ["Todos"];
  String _selectedGroup = "Todos los grupos";
  List<String> _availableGroups = ["Todos los grupos"];
  int _grupoColumnIndex = -1; // Índice de la columna "grupo"
  String _selectedRiskFilter = "Todos los riesgos";
  final List<String> _riskFilterOptions = [
    "Todos los riesgos",
    "Alto riesgo",
    "Medio riesgo",
    "Bajo riesgo",
  ];
  int _recomendacionColumnIndex = -1; // Índice de la columna "recomendaciones"

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    loadCsvData().then((value) {
      setState(() {
        _data = value;
        _filteredData = value;
        _extractGroups();
      });
      _animationController.forward();
    });

    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterData() {
    if (_data == null) return;

    setState(() {
      _filteredData =
          _data!.where((row) {
            final searchTerm = _searchController.text.toLowerCase();
            final matchesSearch = row.any(
              (cell) => cell.toString().toLowerCase().contains(searchTerm),
            );

            // Filtrar por grupo si no es "Todos los grupos"
            bool matchesGroup = true;
            if (_selectedGroup != "Todos los grupos" &&
                _grupoColumnIndex >= 0) {
              matchesGroup =
                  row[_grupoColumnIndex].toString() == _selectedGroup;
            }

            // Filtrar por riesgo si no es "Todos los riesgos"
            bool matchesRisk = true;
            if (_selectedRiskFilter != "Todos los riesgos" &&
                _recomendacionColumnIndex >= 0) {
              if (_recomendacionColumnIndex < row.length) {
                String recomendacion =
                    row[_recomendacionColumnIndex].toString().toLowerCase();
                if (_selectedRiskFilter == "Alto riesgo") {
                  matchesRisk =
                      recomendacion.contains("urgente") ||
                      recomendacion.contains("alto");
                } else if (_selectedRiskFilter == "Medio riesgo") {
                  matchesRisk =
                      recomendacion.contains("atención") ||
                      recomendacion.contains("medio") ||
                      recomendacion.contains("atencion");
                } else if (_selectedRiskFilter == "Bajo riesgo") {
                  matchesRisk =
                      recomendacion.contains("regular") ||
                      recomendacion.contains("bajo");
                }
              }
            }

            return matchesSearch && matchesGroup && matchesRisk;
          }).toList();
    });
  }

  void _extractGroups() {
    if (_data == null || _data!.isEmpty) return;

    final headers = _data![0];

    // Buscar el índice de la columna "grupo"
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].toString().toLowerCase().contains('grupo')) {
        _grupoColumnIndex = i;
      }
      // Buscar columna de recomendaciones
      if (headers[i].toString().toLowerCase().contains('recomendacion')) {
        _recomendacionColumnIndex = i;
      }
    }

    if (_grupoColumnIndex < 0) return;

    // Extraer grupos únicos
    Set<String> grupos = {};
    for (int i = 1; i < _data!.length; i++) {
      if (_grupoColumnIndex < _data![i].length) {
        grupos.add(_data![i][_grupoColumnIndex].toString());
      }
    }

    setState(() {
      _availableGroups = ["Todos los grupos", ...grupos.toList()..sort()];
    });
  }

  Map<String, Map<String, int>> _getGroupStatistics() {
    if (_data == null || _data!.isEmpty || _grupoColumnIndex < 0) {
      return {};
    }

    Map<String, Map<String, int>> groupStats = {};

    for (int i = 1; i < _data!.length; i++) {
      final row = _data![i];
      if (_grupoColumnIndex >= row.length) continue;

      String grupo = row[_grupoColumnIndex].toString();

      if (!groupStats.containsKey(grupo)) {
        groupStats[grupo] = {"total": 0, "alto": 0, "medio": 0, "bajo": 0};
      }

      groupStats[grupo]!["total"] = groupStats[grupo]!["total"]! + 1;

      // Simulación de riesgo
      int riesgo = (i % 3);
      if (riesgo == 0) {
        groupStats[grupo]!["alto"] = groupStats[grupo]!["alto"]! + 1;
      } else if (riesgo == 1) {
        groupStats[grupo]!["medio"] = groupStats[grupo]!["medio"]! + 1;
      } else {
        groupStats[grupo]!["bajo"] = groupStats[grupo]!["bajo"]! + 1;
      }
    }

    return groupStats;
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.logout, color: Color(0xFFEF4444)),
              SizedBox(width: 12),
              Text('Cerrar Sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro que deseas cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                // Navegar al LoginScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _getStatistics() {
    if (_data == null || _data!.isEmpty) {
      return {"total": 0, "alto": 0, "medio": 0, "bajo": 0};
    }

    // Si hay un grupo seleccionado, mostrar stats de ese grupo
    if (_selectedGroup != "Todos los grupos") {
      final groupStats = _getGroupStatistics();
      return groupStats[_selectedGroup] ??
          {"total": 0, "alto": 0, "medio": 0, "bajo": 0};
    }

    // Simulación de estadísticas - ajusta según tu estructura de datos
    final total = _data!.length - 1; // -1 para excluir encabezados
    final alto = (total * 0.15).round();
    final medio = (total * 0.35).round();
    final bajo = total - alto - medio;

    return {"total": total, "alto": alto, "medio": medio, "bajo": bajo};
  }

  Widget _buildGroupDetailCard() {
    final groupStats = _getGroupStatistics();
    final stats = groupStats[_selectedGroup];

    if (stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Grupo Seleccionado",
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        _selectedGroup,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGroupStat("Total", "${stats['total']}", Icons.people),
                  _buildGroupStat("Alto", "${stats['alto']}", Icons.warning),
                  _buildGroupStat("Medio", "${stats['medio']}", Icons.info),
                  _buildGroupStat(
                    "Bajo",
                    "${stats['bajo']}",
                    Icons.check_circle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();
    final groupStats = _getGroupStatistics();

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.dashboard_rounded, size: 28, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Panel de Control Docente",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _cerrarSesion();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFFEF4444)),
                        SizedBox(width: 12),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _data == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Cargando datos...",
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de Grupo
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF3B82F6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.group_rounded,
                                      color: Color(0xFF3B82F6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Filtrar por Grupo",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFF3B82F6)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedGroup,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    items:
                                        _availableGroups.map((String grupo) {
                                          return DropdownMenuItem<String>(
                                            value: grupo,
                                            child: Text(
                                              grupo,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedGroup = newValue;
                                          _filterData();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjetas de grupos (si hay un grupo específico seleccionado)
                      if (_selectedGroup != "Todos los grupos") ...[
                        _buildGroupDetailCard(),
                        const SizedBox(height: 24),
                      ],

                      // Tarjetas de estadísticas
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Total Estudiantes",
                              "${stats['total']}",
                              Icons.people_rounded,
                              Color(0xFF3B82F6),
                              Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "Alto Riesgo",
                              "${stats['alto']}",
                              Icons.warning_rounded,
                              Color(0xFFEF4444),
                              Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Medio Riesgo",
                              "${stats['medio']}",
                              Icons.info_rounded,
                              Color(0xFFF59E0B),
                              Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "Bajo Riesgo",
                              "${stats['bajo']}",
                              Icons.check_circle_rounded,
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Gráfico simple de barras
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF3B82F6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.bar_chart_rounded,
                                      color: Color(0xFF3B82F6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Distribución de Riesgo",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildBarChart(stats),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tabla de datos con filtros
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF3B82F6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.table_chart_rounded,
                                      color: Color(0xFF3B82F6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Datos de Estudiantes",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Barra de búsqueda
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Buscar estudiante...",
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  suffixIcon:
                                      _searchController.text.isNotEmpty
                                          ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                            },
                                          )
                                          : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF3B82F6),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Tabla con encabezado fijo y scroll
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: [
                                      // Encabezado fijo
                                      Container(
                                        color: Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.1),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children:
                                                _data!.isNotEmpty
                                                    ? _data![0].map((header) {
                                                      return Container(
                                                        width: 150,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        child: Text(
                                                          header.toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFF1E293B,
                                                                ),
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList()
                                                    : [],
                                          ),
                                        ),
                                      ),
                                      // Divider
                                      Divider(
                                        height: 1,
                                        color: Colors.grey[300],
                                      ),
                                      // Contenido con scroll
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Column(
                                              children:
                                                  _filteredData!.skip(1).map((
                                                    row,
                                                  ) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color:
                                                                Colors
                                                                    .grey[200]!,
                                                            width: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children:
                                                            row.map((cell) {
                                                              return Container(
                                                                width: 150,
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      16,
                                                                    ),
                                                                child: Text(
                                                                  cell.toString(),
                                                                  style: const TextStyle(
                                                                    color: Color(
                                                                      0xFF475569,
                                                                    ),
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 2,
                                                                ),
                                                              );
                                                            }).toList(),
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Contador de resultados
                              Text(
                                "Mostrando ${_filteredData!.length - 1} de ${_data!.length - 1} estudiantes",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color1,
    Color color2,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1, color2]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> stats) {
    final maxValue = stats.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: [
        _buildBar("Alto", stats['alto']!, maxValue, Color(0xFFEF4444)),
        const SizedBox(height: 16),
        _buildBar("Medio", stats['medio']!, maxValue, Color(0xFFF59E0B)),
        const SizedBox(height: 16),
        _buildBar("Bajo", stats['bajo']!, maxValue, Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildBar(String label, int value, double maxValue, Color color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
