import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/authority_group_model.dart';
import '../../../services/service_providers.dart';

class ManageGroupsDialog extends ConsumerStatefulWidget {
  final List<AuthorityGroupModel> existingGroups;

  const ManageGroupsDialog({super.key, required this.existingGroups});

  static Future<void> show(
    BuildContext context, {
    required List<AuthorityGroupModel> existingGroups,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ManageGroupsDialog(existingGroups: existingGroups),
    );
  }

  @override
  ConsumerState<ManageGroupsDialog> createState() => _ManageGroupsDialogState();
}

class _ManageGroupsDialogState extends ConsumerState<ManageGroupsDialog> {
  Future<void> _editGroupDialog(
    BuildContext context, {
    AuthorityGroupModel? groupToEdit,
  }) async {
    final nameCtrl = TextEditingController(text: groupToEdit?.name ?? '');
    final descCtrl = TextEditingController(text: groupToEdit?.description ?? '');
    final orderCtrl = TextEditingController(
      text: (groupToEdit?.order ?? widget.existingGroups.length + 1).toString(),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(groupToEdit == null ? 'Add Department / Cell' : 'Edit Cell'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Group / Cell Name *',
                    hintText: 'e.g. Women Cell, Executive Council, Tech Wing',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description / Purpose',
                    hintText: 'e.g. Dedicated cell for women leadership & safety',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display Order',
                    hintText: '1, 2, 3...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);

                final id = groupToEdit?.id ?? const Uuid().v4();
                final order = int.tryParse(orderCtrl.text.trim()) ?? 0;
                final group = AuthorityGroupModel(
                  id: id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  order: order,
                  createdAt: groupToEdit?.createdAt ?? DateTime.now(),
                );

                final db = ref.read(databaseRepositoryProvider);
                if (groupToEdit == null) {
                  await db.createAuthorityGroup(group);
                } else {
                  await db.updateAuthorityGroup(group);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${group.name} saved successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    descCtrl.dispose();
    orderCtrl.dispose();
  }

  Future<void> _deleteGroup(BuildContext context, AuthorityGroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Cell / Group?'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? Authorities in this group will remain, but will need to be reassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(databaseRepositoryProvider).deleteAuthorityGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _loadDefaultGroups() async {
    final db = ref.read(databaseRepositoryProvider);
    final defaults = [
      AuthorityGroupModel(
        id: 'executive_council',
        name: 'Executive Council',
        description: 'President, Vice President, and executive governance of the club.',
        order: 1,
      ),
      AuthorityGroupModel(
        id: 'women_cell',
        name: 'Women Cell',
        description: 'Dedicated committee for women leadership, welfare, and empowerment in tech.',
        order: 2,
      ),
      AuthorityGroupModel(
        id: 'technical_wing',
        name: 'Technical Wing',
        description: 'Lead developers, system architects, and technical project heads.',
        order: 3,
      ),
      AuthorityGroupModel(
        id: 'advisory_board',
        name: 'Faculty & Advisory',
        description: 'Faculty advisors, mentors, and alumni patrons.',
        order: 4,
      ),
    ];

    for (final g in defaults) {
      await db.createAuthorityGroup(g);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default groups loaded (Executive Council, Women Cell, Tech Wing, Advisory).'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(authorityGroupsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Manage Club Groups & Cells',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        height: 450,
        child: groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (groups) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create custom domains and cells (such as "Women Cell", "Executive Council", "Technical Wing") to organize authorities and leadership members.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _editGroupDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New Cell / Domain', style: TextStyle(fontSize: 12)),
                    ),
                    if (groups.isEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _loadDefaultGroups,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Load Defaults (incl. Women Cell)', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_work_outlined,
                                size: 48,
                                color: AppColors.textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No authority groups created yet.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Click "Load Defaults" above to quickly create Executive Council, Women Cell, and Technical Wing.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: groups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final g = groups[index];
                            final isWomenCell = g.name.toLowerCase().contains('women');

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isWomenCell
                                      ? const Color(0xFFEC4899).withValues(alpha: 0.5)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isWomenCell
                                          ? const Color(0xFFEC4899).withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isWomenCell
                                          ? Icons.female_rounded
                                          : Icons.group_work_outlined,
                                      color: isWomenCell
                                          ? const Color(0xFFEC4899)
                                          : AppColors.primary,
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
                                            Text(
                                              g.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Order: ${g.order}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (g.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            g.description,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    color: AppColors.textSecondary,
                                    onPressed: () => _editGroupDialog(context, groupToEdit: g),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    color: AppColors.error,
                                    onPressed: () => _deleteGroup(context, g),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
