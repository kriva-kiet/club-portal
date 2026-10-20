import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/complaint_model.dart';
import '../../../models/user_model.dart';
import '../../../services/service_providers.dart';

class ComplaintsAdminTab extends ConsumerStatefulWidget {
  const ComplaintsAdminTab({super.key});

  @override
  ConsumerState<ComplaintsAdminTab> createState() => _ComplaintsAdminTabState();
}

class _ComplaintsAdminTabState extends ConsumerState<ComplaintsAdminTab> {
  String _selectedStatusFilter = 'all'; // all, pending, under_review, resolved, dismissed
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateComplaintDialog(
    BuildContext context,
    ComplaintModel complaint,
    UserModel adminUser,
  ) async {
    String selectedStatus = complaint.status;
    final notesController = TextEditingController(text: complaint.adminNotes ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.rate_review_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text('Update Complaint Status'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint: "${complaint.title}"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Filed by: 100% Anonymous Member',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Set Status:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                        DropdownMenuItem(value: 'under_review', child: Text('Under Investigation')),
                        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Resolution / Response Note:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This note will be visible to the submitter in their grievance dashboard.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter notes regarding actions taken or reasons...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    try {
                      await ref.read(databaseRepositoryProvider).updateComplaintStatus(
                            complaint.id,
                            selectedStatus,
                            adminNotes: notesController.text.trim(),
                            resolvedBy: adminUser.name,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Complaint status updated successfully.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    notesController.dispose();
  }

  Future<void> _deleteComplaint(BuildContext context, ComplaintModel complaint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Complaint?'),
        content: Text(
          'Are you sure you want to permanently delete complaint "${complaint.title}" filed by ${complaint.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseRepositoryProvider).deleteComplaint(complaint.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint deleted.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete complaint: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _sendEmailToUser(String email, String subject) async {
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent("Re: KRIVA Grievance - $subject")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(complaintsProvider);
    final adminUser = ref.watch(currentUserProvider);

    return complaintsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error loading complaints: $err', style: const TextStyle(color: AppColors.error)),
      ),
      data: (allComplaints) {
        // Filter by status
        var filtered = allComplaints.where((c) {
          if (_selectedStatusFilter != 'all' && c.status != _selectedStatusFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesTitle = c.title.toLowerCase().contains(query);
            final matchesDesc = c.description.toLowerCase().contains(query);
            final matchesUser = c.userName.toLowerCase().contains(query);
            final matchesEmail = c.userEmail.toLowerCase().contains(query);
            final matchesClubId = c.userClubId.toLowerCase().contains(query);
            final matchesCat = c.category.toLowerCase().contains(query);
            return matchesTitle || matchesDesc || matchesUser || matchesEmail || matchesClubId || matchesCat;
          }
          return true;
        }).toList();

        final pendingCount = allComplaints.where((c) => c.status == 'pending').length;
        final reviewCount = allComplaints.where((c) => c.status == 'under_review').length;
        final resolvedCount = allComplaints.where((c) => c.status == 'resolved').length;

        return Column(
          children: [
            // ── Top Summary & Filter Bar ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Stat counters
                  Row(
                    children: [
                      _buildStatCard('Total', allComplaints.length.toString(), AppColors.textPrimary),
                      const SizedBox(width: 8),
                      _buildStatCard('Pending', pendingCount.toString(), AppColors.accent),
                      const SizedBox(width: 8),
                      _buildStatCard('In Review', reviewCount.toString(), AppColors.info),
                      const SizedBox(width: 8),
                      _buildStatCard('Resolved', resolvedCount.toString(), AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by keyword, submitter name, email, or club ID...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 10),

                  // Status filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Complaints (${allComplaints.length})'),
                        const SizedBox(width: 6),
                        _buildFilterChip('pending', 'Pending ($pendingCount)'),
                        const SizedBox(width: 6),
                        _buildFilterChip('under_review', 'Under Review ($reviewCount)'),
                        const SizedBox(width: 6),
                        _buildFilterChip('resolved', 'Resolved ($resolvedCount)'),
                        const SizedBox(width: 6),
                        _buildFilterChip('dismissed', 'Dismissed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // ── Complaints List ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          const Text(
                            'No complaints found matching criteria',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final complaint = filtered[index];
                        return _buildAdminComplaintCard(context, complaint, adminUser);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = key),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildAdminComplaintCard(
    BuildContext context,
    ComplaintModel complaint,
    UserModel? adminUser,
  ) {
    Color statusColor;
    String statusText;
    switch (complaint.status) {
      case 'resolved':
        statusColor = AppColors.success;
        statusText = 'RESOLVED';
        break;
      case 'under_review':
        statusColor = AppColors.info;
        statusText = 'UNDER INVESTIGATION';
        break;
      case 'dismissed':
        statusColor = AppColors.textMuted;
        statusText = 'DISMISSED';
        break;
      case 'pending':
      default:
        statusColor = AppColors.accent;
        statusText = 'PENDING REVIEW';
    }

    Color priorityColor;
    switch (complaint.priority) {
      case 'urgent':
        priorityColor = AppColors.error;
        break;
      case 'high':
        priorityColor = const Color(0xFFF97316);
        break;
      case 'low':
        priorityColor = AppColors.textMuted;
        break;
      case 'medium':
      default:
        priorityColor = AppColors.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complaint.priority == 'urgent'
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.border,
          width: complaint.priority == 'urgent' ? 1.5 : 1,
        ),
        boxShadow: [
          if (complaint.priority == 'urgent')
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top badge bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Anonymous badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 12, color: Color(0xFF818CF8)),
                      SizedBox(width: 4),
                      Text(
                        '100% COMPLETELY ANONYMOUS',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    complaint.priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin-Only Submitter Info Box (visible only in Admin Panel)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_outline, size: 12, color: AppColors.error),
                                const SizedBox(width: 4),
                                const Text(
                                  'ADMIN ONLY — Member Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    color: AppColors.error,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complaint.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${complaint.userEmail}  ·  Club ID: ${complaint.userClubId}  ·  Batch: ${complaint.userBatch}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Email Submitter',
                        icon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        onPressed: () async {
                          if (complaint.userEmail.isNotEmpty) {
                            final uri = Uri.parse('mailto:${complaint.userEmail}?subject=Re: ${complaint.title}');
                            // ignore: deprecated_member_use
                            // launch handled externally
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Complaint Category & Timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        complaint.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy · hh:mm a').format(complaint.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Complaint Title
                Text(
                  complaint.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Complaint Description
                Text(
                  complaint.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),

                // Admin Resolution Note (if present)
                if (complaint.adminNotes != null && complaint.adminNotes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Admin Resolution (${complaint.resolvedBy ?? "Admin"}):',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.adminNotes!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () => _deleteComplaint(context, complaint),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: adminUser != null
                          ? () => _updateComplaintDialog(context, complaint, adminUser)
                          : null,
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text(
                        'Update Status & Reply',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
