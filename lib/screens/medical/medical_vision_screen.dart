import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/medical_vision_result_model.dart';
import '../../services/medical_vision_service.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/medical_theme.dart';
import '../../widgets/bullet_list_card.dart';

enum MedicalVisionMode { injury, gym }

class MedicalVisionScreen extends StatefulWidget {
  const MedicalVisionScreen({super.key, this.mode = MedicalVisionMode.injury});

  final MedicalVisionMode mode;

  @override
  State<MedicalVisionScreen> createState() => _MedicalVisionScreenState();
}

class _MedicalVisionScreenState extends State<MedicalVisionScreen> {
  final ImagePicker _picker = ImagePicker();
  final MedicalVisionService _service = MedicalVisionService();

  XFile? _selectedFile;
  Uint8List? _previewBytes;
  MedicalVisionResultModel? _result;
  bool _isLoading = false;
  String? _error;

  bool get _isGym => widget.mode == MedicalVisionMode.gym;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) {
      return;
    }

    final bytes = await _service.readPreviewBytes(file);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedFile = file;
      _previewBytes = bytes;
      _result = null;
      _error = null;
      _isLoading = true;
    });

    try {
      final result = _isGym
          ? await _service.detectGym(file)
          : await _service.detectInjury(file);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGym = _isGym;
    final title = isGym ? 'Gym Equipment AI' : 'Injury Camera AI';
    final subtitle = isGym
        ? 'Identify equipment and muscle focus.'
        : 'Scan an injury photo for quick classification.';
    return MedicalThemeScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: title,
              subtitle: subtitle,
              action: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _ActionRow(
              onCamera: () => _pickAndAnalyze(ImageSource.camera),
              onGallery: () => _pickAndAnalyze(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.s16),
            _PreviewCard(
              bytes: _previewBytes,
              isLoading: _isLoading,
              hasSelection: _selectedFile != null,
            ),
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              _InlineError(message: _error!),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppSpacing.s16),
              _ResultHeader(
                title: isGym ? 'Equipment result' : 'Injury result',
                name: isGym ? _result!.equipmentName : _result!.injuryName,
                confidence: _result!.confidence,
              ),
              const SizedBox(height: AppSpacing.s12),
              _TopPredictions(result: _result!),
              const SizedBox(height: AppSpacing.s16),
              if (isGym)
                _MuscleFocusCard(muscles: _result!.muscles)
              else ...[
                BulletListCard(
                  title: 'Advice',
                  items: _result!.advice,
                  icon: Icons.local_hospital_rounded,
                ),
                const SizedBox(height: AppSpacing.s12),
                BulletListCard(
                  title: 'Rehab steps',
                  items: _result!.rehab,
                  icon: Icons.fitness_center_rounded,
                ),
              ],
              const SizedBox(height: AppSpacing.s12),
              _InfoFooter(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.bytes,
    required this.isLoading,
    required this.hasSelection,
  });

  final Uint8List? bytes;
  final bool isLoading;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MedicalTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Captured image',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: MedicalTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MedicalTheme.cardBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(bytes!, fit: BoxFit.cover),
                  )
                else
                  Center(
                    child: Text(
                      hasSelection
                          ? 'No preview available'
                          : 'No image selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MedicalTheme.textMuted,
                      ),
                    ),
                  ),
                if (isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: MedicalTheme.background.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.title,
    required this.name,
    required this.confidence,
  });

  final String title;
  final String name;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (confidence * 100).clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MedicalTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 10,
                    backgroundColor: MedicalTheme.surfaceAlt,
                    color: MedicalTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${confidencePercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopPredictions extends StatelessWidget {
  const _TopPredictions({required this.result});

  final MedicalVisionResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MedicalTheme.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top predictions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.topK.map((entry) {
              final score = (entry.confidence * 100).clamp(0, 100).toDouble();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MedicalTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MedicalTheme.cardBorder),
                ),
                child: Text(
                  '${entry.label}  ${score.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MedicalTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MuscleFocusCard extends StatelessWidget {
  const _MuscleFocusCard({required this.muscles});

  final List<String> muscles;

  @override
  Widget build(BuildContext context) {
    final safeMuscles = muscles.isEmpty ? const ['No muscle data'] : muscles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MedicalTheme.softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muscle focus', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: safeMuscles.map((muscle) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MedicalTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MedicalTheme.cardBorder),
                ),
                child: Text(
                  muscle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MedicalTheme.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MedicalTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedicalTheme.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: MedicalTheme.textPrimary, fontSize: 12),
      ),
    );
  }
}

class _InfoFooter extends StatelessWidget {
  const _InfoFooter({required this.result});

  final MedicalVisionResultModel result;

  @override
  Widget build(BuildContext context) {
    final model = result.model ?? 'model';
    final inferenceMs = result.inferenceMs ?? 0;
    return Text(
      'Model: $model  •  ${inferenceMs}ms',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
