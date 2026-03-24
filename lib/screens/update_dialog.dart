import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService updateService;
  const UpdateDialog({super.key, required this.updateService});

  static Future<void> show(BuildContext context, UpdateService updateService) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateService: updateService),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.updateService.latestVersion;
    if (version == null) return const SizedBox();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16162A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AiprayTheme.gold.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AiprayTheme.gold.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ValueListenableBuilder<UpdateState>(
          valueListenable: widget.updateService.state,
          builder: (context, state, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with sparkle effect
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AiprayTheme.gold.withValues(alpha: 0.15),
                        AiprayTheme.gold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Animated icon
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AiprayTheme.gold,
                                  AiprayTheme.gold.withValues(alpha: 0.6),
                                  AiprayTheme.gold,
                                ],
                                stops: [
                                  0.0,
                                  _shimmerController.value,
                                  1.0,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AiprayTheme.gold.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              state == UpdateState.readyToInstall
                                  ? Icons.check_circle
                                  : state == UpdateState.downloading
                                      ? Icons.downloading
                                      : Icons.system_update,
                              color: const Color(0xFF0D0D0D),
                              size: 36,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state == UpdateState.readyToInstall
                            ? 'พร้อมติดตั้ง!'
                            : state == UpdateState.downloading
                                ? 'กำลังดาวน์โหลด...'
                                : 'มีเวอร์ชันใหม่!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AiprayTheme.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'v${UpdateService.currentVersion} → v${version.version}',
                          style: TextStyle(
                            color: AiprayTheme.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Download progress
                      if (state == UpdateState.downloading) ...[
                        ValueListenableBuilder<double>(
                          valueListenable: widget.updateService.downloadProgress,
                          builder: (context, progress, _) {
                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: AiprayTheme.gold.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation(AiprayTheme.gold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: AiprayTheme.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      widget.updateService.fileSizeFormatted,
                                      style: const TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
                      ],

                      // Release notes
                      if (state != UpdateState.downloading && version.releaseNotes.isNotEmpty) ...[
                        const Text(
                          'มีอะไรใหม่',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Text(
                              version.releaseNotes,
                              style: const TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // File size info
                      if (state == UpdateState.updateAvailable) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.download, color: AiprayTheme.gold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'ขนาดไฟล์: ${widget.updateService.fileSizeFormatted}',
                                style: const TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Error state
                      if (state == UpdateState.error) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ดาวน์โหลดไม่สำเร็จ กรุณาลองอีกครั้ง',
                                  style: TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _buildButtons(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtons(UpdateState state) {
    switch (state) {
      case UpdateState.updateAvailable:
      case UpdateState.error:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => widget.updateService.downloadUpdate(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AiprayTheme.gold,
                  foregroundColor: const Color(0xFF0D0D0D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: AiprayTheme.gold.withValues(alpha: 0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('ดาวน์โหลดอัปเดต',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.updateService.skipVersion();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ข้ามเวอร์ชันนี้',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ไว้ทีหลัง',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case UpdateState.downloading:
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AiprayTheme.gold.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'กำลังดาวน์โหลด...',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
        );

      case UpdateState.readyToInstall:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await widget.updateService.installUpdate();
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ติดตั้งไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.install_mobile, size: 20),
                    SizedBox(width: 8),
                    Text('ติดตั้งเลย',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ไว้ทีหลัง',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
          ],
        );

      default:
        return TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด', style: TextStyle(color: Color(0xFF888888))),
        );
    }
  }
}
