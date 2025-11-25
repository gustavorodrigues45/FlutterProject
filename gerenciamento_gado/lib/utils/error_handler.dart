import 'package:flutter/material.dart';

/// Gerenciador centralizado de erros e mensagens
class ErrorHandler {
  // Exibir erro ao usuário
  static void mostrarErro(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Exibir sucesso ao usuário
  static void mostrarSucesso(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Exibir aviso ao usuário
  static void mostrarAviso(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Exibir informação ao usuário
  static void mostrarInfo(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Diálogo de erro
  static void mostrarDialogoErro(BuildContext context, {
    required String titulo,
    required String mensagem,
    VoidCallback? onOk,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmação
  static Future<bool> mostrarDialogoConfirmacao(BuildContext context, {
    required String titulo,
    required String mensagem,
    String textoBotaoSim = 'Sim',
    String textoBotaoNao = 'Não',
  }) async {
    if (!context.mounted) return false;
    
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(textoBotaoNao),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(textoBotaoSim),
          ),
        ],
      ),
    );
    
    return resultado ?? false;
  }

  // Tratar exceções comuns
  static String obterMensagemErro(dynamic erro) {
    if (erro is ArgumentError) {
      return erro.message.toString();
    }
    if (erro is StateError) {
      return erro.message;
    }
    if (erro is FormatException) {
      return 'Formato de dados inválido';
    }
    if (erro is Exception) {
      return erro.toString().replaceAll('Exception: ', '');
    }
    return 'Erro inesperado: ${erro.toString()}';
  }

  // Loading indicator
  static void mostrarCarregando(BuildContext context, {String? mensagem}) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (mensagem != null) ...[
                    const SizedBox(height: 16),
                    Text(mensagem),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fechar loading
  static void fecharCarregando(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
