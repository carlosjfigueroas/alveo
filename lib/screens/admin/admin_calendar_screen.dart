import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';
import '../../services/supabase_service.dart';
import '../../providers/company_provider.dart';
import '../../widgets/admin_drawer.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  Map<String, String> _propertyTitles = {};
  Map<String, String> _propertyRefs = {};
  List<Map<String, dynamic>> _agents = [];
  String? _selectedAgentId; // For filtering the calendar view

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final agentId = appProv.userProfile?.role == 'agent' ? appProv.userProfile?.id : null;
      
      var apps = <Map<String, dynamic>>[];
      var agents = <Map<String, dynamic>>[];
      
      if (companyId.isNotEmpty) {
        apps = await _service.getAppointments(companyId, agentId: agentId).timeout(const Duration(seconds: 15));
        agents = await _service.getCompanyUsers(companyId).timeout(const Duration(seconds: 15));
      }
      
      final props = companyId.isNotEmpty 
          ? await _service.getAllProperties(companyId).timeout(const Duration(seconds: 15))
          : await _service.getAllPropertiesGlobal().timeout(const Duration(seconds: 15));

      final titles = {for (var p in props) p.id: p.title ?? 'Sin Título'};
      final refs = {for (var p in props) p.id: p.refNumber?.toString() ?? ''};
      
      if (companyId.isEmpty) {
        apps = await _service.getAllAppointmentsGlobal().timeout(const Duration(seconds: 15));
      }

      if (mounted) {
        setState(() {
          _appointments = apps;
          _propertyTitles = titles;
          _propertyRefs = refs;
          _agents = agents;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Agenda Load Error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get("error_generic")}$e'), duration: const Duration(seconds: 10)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _appointments.where((app) {
      final appDateStr = app['appointment_date'] as String?;
      if (appDateStr == null) return false;
      final appDate = DateTime.tryParse(appDateStr);
      if (appDate == null) return false;
      
      // Filter by agent if selected
      if (_selectedAgentId != null && app['assigned_agent_id'] != _selectedAgentId) {
        return false;
      }
      
      return isSameDay(appDate, day);
    }).toList()
      ..sort((a, b) {
        final timeA = a['appointment_time'] ?? '00:00';
        final timeB = b['appointment_time'] ?? '00:00';
        return timeA.compareTo(timeB);
      });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'done':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showAppointmentDialog({Map<String, dynamic>? appointment}) async {
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final isNew = appointment == null;
    final l10n = AppLocalizations.of(context);

    final nameController = TextEditingController(text: appointment?['client_name']);
    final phoneController = TextEditingController(text: appointment?['phone']);
    DateTime dialogDate = _selectedDay ?? DateTime.now();
    if (!isNew && appointment['appointment_date'] != null) {
      dialogDate = DateTime.tryParse(appointment['appointment_date']) ?? dialogDate;
    }
    
    String dialogTime = '09:00';
    if (!isNew && appointment['appointment_time'] != null) {
      final t = appointment['appointment_time'].toString();
      dialogTime = t.length >= 5 ? t.substring(0, 5) : t;
    }

    String selectedStatus = appointment?['appointment_status'] ?? 'pending';
    String? selectedAgentId = appointment?['assigned_agent_id'];
    String? selectedPropertyId;
    if (!isNew && appointment != null && appointment['property_list'] != null && appointment['property_list'].isNotEmpty) {
      selectedPropertyId = appointment['property_list'][0];
    }
    final refController = TextEditingController(text: selectedPropertyId != null ? _propertyRefs[selectedPropertyId] : null);
    String? propertySearchQuery;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // Generate time slots (07:00 to 21:00)
            final timeSlots = <String>[];
            for (int h = 7; h <= 21; h++) {
              timeSlots.add('${h.toString().padLeft(2, '0')}:00');
              timeSlots.add('${h.toString().padLeft(2, '0')}:30');
            }

            return AlertDialog(
              title: Text(isNew ? l10n.get('agenda_new_appointment') : l10n.get('agenda_edit_appointment')),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.get('client_name'),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: l10n.get('phone'),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      // Date Selector
                      ListTile(
                        title: Text('${l10n.get('agenda_date')}: ${dialogDate.year}-${dialogDate.month.toString().padLeft(2, '0')}-${dialogDate.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogCtx,
                            initialDate: dialogDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setDialogState(() => dialogDate = picked);
                        },
                      ),
                      // Time Selector
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.get('agenda_time'),
                          border: const OutlineInputBorder(),
                        ),
                        value: dialogTime,
                        items: timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => dialogTime = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Property Search (Ref Number)
                      TextFormField(
                        controller: refController,
                        decoration: InputDecoration(
                          labelText: l10n.get('agenda_prop_ref') ?? 'Ref. Propiedad / Prop. Ref.',
                          hintText: 'e.g. 101',
                          border: const OutlineInputBorder(),
                          suffixIcon: selectedPropertyId != null 
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setDialogState(() {
                                selectedPropertyId = null;
                                refController.clear();
                              })) 
                            : null,
                        ),
                        onChanged: (v) {
                          setDialogState(() {
                            propertySearchQuery = v.trim().toLowerCase();
                            selectedPropertyId = null;
                          });
                        },
                      ),
                      if (propertySearchQuery != null && propertySearchQuery!.isNotEmpty && selectedPropertyId == null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _propertyRefs.entries
                              .where((e) {
                                final currentRef = e.value.toLowerCase();
                                return currentRef.contains(propertySearchQuery!) && currentRef.isNotEmpty;
                              })
                              .take(5)
                              .map((e) => Container(
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      title: Text('${l10n.get('ref')} ${e.value} - ${_propertyTitles[e.key]}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onTap: () => setDialogState(() {
                                        selectedPropertyId = e.key;
                                        refController.text = e.value;
                                        propertySearchQuery = null;
                                      }),
                                    ),
                                  ))
                              .toList(),
                        ),
                      if (selectedPropertyId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${l10n.get('selected_label')}: ${l10n.get('ref')} ${_propertyRefs[selectedPropertyId]} - ${_propertyTitles[selectedPropertyId]}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.get('agenda_status'),
                          border: const OutlineInputBorder(),
                        ),
                        value: selectedStatus,
                        items: ['pending', 'confirmed', 'cancelled', 'done'].map((s) => DropdownMenuItem(value: s, child: Text(l10n.get('agenda_status_$s') ?? s))).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedStatus = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Agent Selector
                      DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: l10n.get('agenda_assigned_agent'),
                          border: const OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        value: _agents.any((a) => a['id'] == selectedAgentId) ? selectedAgentId : null,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('-- ${l10n.get('agenda_select_agent')} --'),
                          ),
                          ..._agents.map((a) => DropdownMenuItem<String?>(
                                value: a['id'],
                                child: Text(a['full_name'] ?? a['id']),
                              )),
                        ],
                        onChanged: (v) {
                          setDialogState(() => selectedAgentId = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: dialogCtx,
                        builder: (_) => AlertDialog(
                          title: Text(l10n.get('delete')),
                          content: Text(l10n.get('agenda_delete_confirm')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text(l10n.get('cancel'))),
                            TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(dialogCtx);
                        
                        setState(() => _isLoading = true);
                        try {
                          await _service.deleteAppointment(appointment['id']).timeout(const Duration(seconds: 15));
                          if (mounted) {
                            navigator.pop(); // close appointment dialog
                            scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.get('agenda_deleted'))));
                            _loadAppointments();
                          }
                        } catch (e) {
                          debugPrint('Agenda Delete Error: $e');
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(SnackBar(content: Text('${l10n.get("error_generic")}$e')));
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
                    child: Text(l10n.get('delete'), style: const TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.get('cancel')),
                ),
                ElevatedButton(
                  onPressed: selectedPropertyId == null ? null : () async {
                    if (formKey.currentState!.validate()) {
                      // Move this out into a local variable before we potentially lose context
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(dialogCtx);
                      
                      setState(() => _isLoading = true);
                      try {
                        final data = {
                          'client_name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'date': '${dialogDate.year}-${dialogDate.month.toString().padLeft(2, '0')}-${dialogDate.day.toString().padLeft(2, '0')}',
                          'time': '$dialogTime:00',
                          'property_id': selectedPropertyId,
                          'status': selectedStatus,
                          'agent_id': selectedAgentId,
                        };
                        
                        if (isNew) {
                          await _service.createAppointment(data, companyId).timeout(const Duration(seconds: 15));
                        } else {
                          await _service.updateAppointment(appointment['id'], data).timeout(const Duration(seconds: 15));
                        }
                        
                        if (mounted) {
                          navigator.pop();
                          scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.get('agenda_saved'))));
                          _loadAppointments();
                        }
                      } catch (e) {
                        debugPrint('Agenda Save Error: $e');
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(SnackBar(content: Text('${l10n.get("error_generic")}$e')));
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
                  child: Text(l10n.get('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('agenda')),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Agent Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.person_search, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _selectedAgentId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: Text(l10n.get('agenda_all_agents')),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.get('agenda_all_agents')),
                            ),
                            ..._agents.map((a) => DropdownMenuItem<String?>(
                                  value: a['id'],
                                  child: Text(a['full_name'] ?? a['id']),
                                )),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedAgentId = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                TableCalendar<Map<String, dynamic>>(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  locale: Localizations.localeOf(context).languageCode,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getEventsForDay,
                  availableCalendarFormats: {
                    CalendarFormat.month: l10n.get('agenda_month_view'),
                    CalendarFormat.week: l10n.get('agenda_week_view'),
                    CalendarFormat.twoWeeks: '2 ${l10n.get('agenda_week_view')}',
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox();
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((event) {
                            final status = event['appointment_status'] ?? 'pending';
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor(status),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: selectedEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(l10n.get('agenda_no_appointments'), style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedEvents.length,
                            itemBuilder: (context, index) {
                              final app = selectedEvents[index];
                              final status = app['appointment_status'] ?? 'pending';
                              final time = app['appointment_time']?.toString().substring(0, 5) ?? '';
                              String propName = l10n.get('unknown');
                              if (app['property_list'] != null && app['property_list'].isNotEmpty) {
                                propName = _propertyTitles[app['property_list'][0]] ?? app['property_list'][0];
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Icon(Icons.circle, size: 12, color: _statusColor(status)),
                                    ],
                                  ),
                                  title: Text(app['client_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$propName\n${app['phone'] ?? ''}'),
                                      if (app['assigned_agent_id'] != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            Text(
                                              _agents.firstWhere((a) => a['id'] == app['assigned_agent_id'], orElse: () => {'full_name': l10n.get('role_agent')})['full_name'],
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAppointmentDialog(appointment: app),
                                  ),
                                  onTap: () => _showAppointmentDialog(appointment: app),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentDialog(),
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
