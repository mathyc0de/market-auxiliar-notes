import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:market_invoices_app/methods/ai_services.dart';
import 'package:market_invoices_app/methods/database.dart' show Item, db;
import 'package:market_invoices_app/methods/str_manipulation.dart' show speechToList;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:market_invoices_app/widgets/dialogs.dart' show ErrorDialog;

class SpeechDialog extends StatefulWidget {
  const SpeechDialog({super.key, required this.tableid});
  final int tableid;

  @override
  State<SpeechDialog> createState() => _SpeechDialogState();
}

class _SpeechDialogState extends State<SpeechDialog> {
  final SpeechToText _speech = SpeechToText();
  String _speechText = "";
  final List<String> _items = [];
  List<dynamic> _decoded = [];
  String? _out;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void onStatus(String status) {
    if (status == "done") {
      if (_speechText.isNotEmpty) {
        _items.add(_speechText);
        _speechText = "";
      }
    }
    setState(() {});
  }

  Future<void> _initSpeech() async {
    if (!_speech.isAvailable) {
      await _speech.initialize(
        onStatus: onStatus,
        finalTimeout: const Duration(seconds: 2),
      );
      setState(() {});
      return;
    }
    _speech.statusListener = onStatus;
  }

  Future<void> start() async {
    await _speech.listen(
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(cancelOnError: true),
      onResult: (result) {
        setState(() => _speechText = result.recognizedWords);
      },
    );
    setState(() {});
  }

  Future<bool> uploadStatus() async {
    if (_out == null) {
      await showDialog(
        context: context,
        builder: (context) => const ErrorDialog(
          errorMessage:
              'Erro de conexão. Verifique sua internet e tente novamente.',
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> processs() async {
    await _speech.stop();
    final String input = _items.join("\n");
    _out = await sendToGroq(input, Prompt.sellPagePrompt);
    _decoded = jsonDecode(_out!);
    if (!(await uploadStatus())) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  Future<void> addToDB() async {
    try {
      final List<Item> items = speechToList(_decoded, widget.tableid);
      for (final item in items) {
        await db.insertItem(item);
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const ErrorDialog(
          errorMessage:
              'Houve um erro ao adicionar os itens. Verifique quantidade, nome e preço.',
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_speech.isAvailable) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_decoded.isNotEmpty) {
      return AlertDialog(
        title: const Text('Confirmar produtos'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in _decoded)
                  Material(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        "${item['quantidade'] ?? '?'} ${item['formato'] ?? '?'} ${item['nome'] ?? '?'}",
                      ),
                      subtitle: Text("R\$ ${item['preço'] ?? '?'}"),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: colorScheme.error),
                        onPressed: () => setState(() => _decoded.remove(item)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: addToDB,
            child: const Text('Adicionar'),
          ),
        ],
      );
    }

    return Dialog(
      child: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adicionar por voz', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _speech.isListening
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHigh,
                  foregroundColor: _speech.isListening
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                onPressed: _speech.isListening ? null : start,
                icon: const Icon(Icons.mic_none),
              ),
              const SizedBox(height: 8),
              Text(
                _speech.isListening ? 'Ouvindo...' : 'Toque para falar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (int i = 0; i < _items.length; i++)
                  Material(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      dense: true,
                      title: Text(_items[i]),
                      trailing: IconButton(
                        icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _items.isNotEmpty ? processs : null,
                    child: const Text('Processar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
