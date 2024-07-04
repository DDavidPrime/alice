import 'package:alice/model/alice_translation.dart';
import 'package:alice/ui/common/alice_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget which displays raw logs list (logs collected with ADB).
class AliceRawLogListWidget extends StatelessWidget {
  const AliceRawLogListWidget({
    required this.scrollController,
    required this.getRawLogs,
    required this.emptyWidget,
    super.key,
  });

  final ScrollController scrollController;
  final Future<String>? getRawLogs;
  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getRawLogs,
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data?.isNotEmpty == true) {
            return Scrollbar(
              thickness: 8,
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onLongPress: () => _copyToClipboard(
                      context: context,
                      text: snapshot.data ?? '',
                    ),
                    child: Text(
                      snapshot.data ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            );
          }
          return emptyWidget;
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Copies provided text to clipboard and displays info about it.
  Future<void> _copyToClipboard({
    required BuildContext context,
    required String text,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.i18n(
              AliceTranslationKey.logsCopied,
            ),
          ),
        ),
      );
    }
  }
}
