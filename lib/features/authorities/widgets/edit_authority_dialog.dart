import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/authority_model.dart';
import '../../../models/authority_group_model.dart';
import '../../../models/user_model.dart';
import '../../../services/service_providers.dart';
import '../../../widgets/app_avatar.dart';

class EditAuthorityDialog extends ConsumerStatefulWidget {
  final AuthorityModel? existingAuthority;
  final List<AuthorityGroupModel> groups;

  const EditAuthorityDialog({
    super.key,
    this.existingAuthority,
    required this.groups,
  });

  static Future<void> show(
    BuildContext context, {
    AuthorityModel? existingAuthority,
    required List<AuthorityGroupModel> groups,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAuthorityDialog(
        existingAuthority: existingAuthority,
        groups: groups,
      ),
    );
  }

  @override
  ConsumerState<EditAuthorityDialog> createState() => _EditAuthorityDialogState();
}

class _EditAuthorityDialogState extends ConsumerState<EditAuthorityDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;
  late TextEditingController _orderController;
  late TextEditingController _photoUrlController;

  String? _selectedGroupId;
  String _selectedGroupName = '';
  String _currentPhotoData = '';
  String _linkedUserId = '';
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _memberImported = false;

  @override
  void initState() {
    super.initState();
    final auth = widget.existingAuthority;

    _nameController = TextEditingController(text: auth?.name ?? '');
    _positionController = TextEditingController(text: auth?.position ?? '');
    _emailController = TextEditingController(text: auth?.email ?? '');
    _phoneController = TextEditingController(text: auth?.phone ?? '');
    _linkedinController = TextEditingController(text: auth?.linkedinUrl ?? '');
    _githubController = TextEditingController(text: auth?.githubUrl ?? '');
    _instagramController = TextEditingController(text: auth?.instagramUrl ?? '');
    _bioController = TextEditingController(text: auth?.bio ?? '');
    _orderController = TextEditingController(text: (auth?.order ?? 0).toString());
    _photoUrlController = TextEditingController(text: auth?.photoUrl ?? '');

    _currentPhotoData = auth?.photoUrl ?? '';
    _linkedUserId = auth?.userId ?? '';

    if (auth != null && auth.groupId.isNotEmpty) {
      _selectedGroupId = auth.groupId;
      _selectedGroupName = auth.groupName;
    } else if (widget.groups.isNotEmpty) {
      _selectedGroupId = widget.groups.first.id;
      _selectedGroupName = widget.groups.first.name;
    } else {
      _selectedGroupId = 'executive_council';
      _selectedGroupName = 'Executive Council';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    _orderController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isUploadingPhoto = true);
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isEmpty) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      if (bytes.lengthInBytes > 700 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected image is too large (max 700KB). Please choose a smaller photo.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/png;base64,$base64String';

      setState(() {
        _currentPhotoData = dataUrl;
        _photoUrlController.text = dataUrl;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Shows a search dialog to pick a club member and auto-fill the form
  Future<void> _importFromMember(BuildContext context) async {
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.valueOrNull ?? [];

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No members found. Make sure members have been approved.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final searchCtrl = TextEditingController();
    String query = '';

    final selected = await showDialog<UserModel>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = query.isEmpty
                ? members
                : members.where((m) {
                    final q = query.toLowerCase();
                    return m.name.toLowerCase().contains(q) ||
                        m.email.toLowerCase().contains(q) ||
                        m.clubId.toLowerCase().contains(q);
                  }).toList();

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.group_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Import from Club Member',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or club ID...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) => setDialogState(() => query = val.trim()),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No members match your search.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, idx) {
                                final m = filtered[idx];
                                return ListTile(
                                  leading: AppAvatar(
                                    photoUrl: m.photoUrl,
                                    name: m.name,
                                    radius: 18,
                                  ),
                                  title: Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${m.email}  ·  ${m.batch}  ·  ${m.role.name.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      m.clubId,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, m),
                                );
                              },
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
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _nameController.text = selected.name;
        _emailController.text = selected.email;
        if (selected.linkedinId.isNotEmpty) {
          _linkedinController.text = selected.linkedinId.startsWith('http')
              ? selected.linkedinId
              : 'https://linkedin.com/in/${selected.linkedinId}';
        }
        if (selected.githubId.isNotEmpty) {
          _githubController.text = selected.githubId.startsWith('http')
              ? selected.githubId
              : 'https://github.com/${selected.githubId}';
        }
        if (selected.instagramId.isNotEmpty) {
          _instagramController.text = selected.instagramId.startsWith('http')
              ? selected.instagramId
              : 'https://instagram.com/${selected.instagramId}';
        }
        if (selected.photoUrl.isNotEmpty) {
          _currentPhotoData = selected.photoUrl;
          _photoUrlController.text = selected.photoUrl;
        }
        _linkedUserId = selected.uid;
        _memberImported = true;
      });
    }
  }

  Future<void> _saveAuthority() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseRepositoryProvider);
      final isNew = widget.existingAuthority == null;
      final id = widget.existingAuthority?.id ?? const Uuid().v4();
      final order = int.tryParse(_orderController.text.trim()) ?? 0;

      // Group name lookup
      String groupName = _selectedGroupName;
      if (_selectedGroupId != null) {
        final found = widget.groups.where((g) => g.id == _selectedGroupId);
        if (found.isNotEmpty) {
          groupName = found.first.name;
        }
      }

      // Auto-detect linked userId from existing members if not explicitly set
      String finalUserId = _linkedUserId;
      if (finalUserId.isEmpty) {
        final email = _emailController.text.trim().toLowerCase();
        final members = ref.read(membersProvider).valueOrNull ?? [];
        final match = members.where((m) => m.email.toLowerCase() == email);
        if (match.isNotEmpty) {
          finalUserId = match.first.uid;
        }
      }

      final authority = AuthorityModel(
        id: id,
        userId: finalUserId,
        name: _nameController.text.trim(),
        position: _positionController.text.trim(),
        groupId: _selectedGroupId ?? 'executive_council',
        groupName: groupName.isNotEmpty ? groupName : 'Executive Council',
        photoUrl: _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : _currentPhotoData,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        githubUrl: _githubController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        bio: _bioController.text.trim(),
        order: order,
        isActive: true,
        createdAt: widget.existingAuthority?.createdAt ?? DateTime.now(),
      );

      if (isNew) {
        await db.createAuthority(authority);
      } else {
        await db.updateAuthority(authority);
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew
                ? 'Authority position added successfully.'
                : 'Authority details updated successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save authority: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingAuthority == null;

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
            child: Icon(
              isNew ? Icons.person_add_rounded : Icons.edit_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNew ? 'Add Authority Position' : 'Edit Authority Details',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 11, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Developed by Abhisht Singh',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar preview and picker row
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: AppAvatar(
                              photoUrl: _photoUrlController.text.trim().isNotEmpty
                                  ? _photoUrlController.text.trim()
                                  : _currentPhotoData,
                              name: _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()
                                  : 'Authority',
                              radius: 46,
                              borderWidth: 2.5,
                              borderColor: AppColors.primary,
                            ),
                          ),
                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isUploadingPhoto ? null : _pickImage,
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Upload Photo', style: TextStyle(fontSize: 12)),
                          ),
                          if (_currentPhotoData.isNotEmpty ||
                              _photoUrlController.text.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _currentPhotoData = '';
                                  _photoUrlController.clear();
                                });
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Clear', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Import from Member button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF818CF8),
                      side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    ),
                    onPressed: () => _importFromMember(context),
                    icon: const Icon(Icons.person_search_rounded, size: 18),
                    label: Text(
                      _memberImported
                          ? '✓ Member imported — Change Member'
                          : '⚡ Fetch & Import from Club Members',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Position
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Abhisht Singh',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter full name' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Position / Title *',
                          hintText: 'e.g. President, Vice President',
                          prefixIcon: const Icon(Icons.workspace_premium_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter title' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Group / Domain Cell Dropdown & Order
                Builder(
                  builder: (context) {
                    final availableGroups = widget.groups.isNotEmpty
                        ? widget.groups
                        : [
                            AuthorityGroupModel(
                              id: 'executive_council',
                              name: 'Executive Council',
                              description: 'Executive leadership & council',
                              order: 1,
                            ),
                            AuthorityGroupModel(
                              id: 'women_cell',
                              name: 'Women Cell',
                              description: 'Women leadership & empowerment',
                              order: 2,
                            ),
                          ];

                    final groupIds = availableGroups.map((g) => g.id).toSet();
                    final selectedVal = (_selectedGroupId != null && groupIds.contains(_selectedGroupId))
                        ? _selectedGroupId
                        : availableGroups.first.id;

                    return Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            value: selectedVal,
                            decoration: InputDecoration(
                              labelText: 'Department / Cell / Domain *',
                              prefixIcon: const Icon(Icons.group_work_outlined, size: 18),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: availableGroups.map((g) {
                              return DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final g = availableGroups.firstWhere((x) => x.id == val);
                                setState(() {
                                  _selectedGroupId = val;
                                  _selectedGroupName = g.name;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _orderController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Display Order',
                              hintText: 'e.g. 1, 2, 3',
                              prefixIcon: const Icon(Icons.sort_rounded, size: 18),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Direct Photo URL (optional alternative)
                TextFormField(
                  controller: _photoUrlController,
                  decoration: InputDecoration(
                    labelText: 'Direct Photo URL (Optional)',
                    hintText: 'https://... (or use Upload Photo above)',
                    prefixIcon: const Icon(Icons.link_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Email & Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'president@club.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter email' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+91 9876543210',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Social Links (LinkedIn, GitHub, Instagram)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _linkedinController,
                        decoration: InputDecoration(
                          labelText: 'LinkedIn URL / Username',
                          hintText: 'https://linkedin.com/in/...',
                          prefixIcon: const Icon(Icons.link_rounded, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _githubController,
                        decoration: InputDecoration(
                          labelText: 'GitHub Profile',
                          hintText: 'https://github.com/...',
                          prefixIcon: const Icon(Icons.code_rounded, size: 18),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram / Portfolio Link',
                    hintText: 'https://instagram.com/...',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bio / Vision
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio & Message to Members',
                    hintText: 'Short message, vision, or guidance for community members...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sync_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Live Synced with Account Data · Dev: Abhisht Singh',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : _saveAuthority,
          child: Text(_isSaving ? 'Saving...' : 'Save Authority'),
        ),
      ],
    );
  }
}
