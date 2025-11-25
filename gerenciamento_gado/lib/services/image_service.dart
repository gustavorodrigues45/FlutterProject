import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<String?> selecionarImagem({required ImageSource source}) async {
    try {
      final XFile? imagemSelecionada = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (imagemSelecionada == null) return null;

      // Salvar imagem no diretório de documentos do app
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String imagePath = path.join(
        appDocDir.path,
        'fotos_gado',
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Criar diretório se não existir
      final Directory imageDir = Directory(path.dirname(imagePath));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Copiar imagem para o diretório
      await File(imagemSelecionada.path).copy(imagePath);

      return imagePath;
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  Future<String?> capturarFoto() async {
    return await selecionarImagem(source: ImageSource.camera);
  }

  Future<String?> selecionarDaGaleria() async {
    return await selecionarImagem(source: ImageSource.gallery);
  }

  Future<bool> deletarImagem(String caminhoImagem) async {
    try {
      final File arquivo = File(caminhoImagem);
      if (await arquivo.exists()) {
        await arquivo.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao deletar imagem: $e');
      return false;
    }
  }

  File? obterArquivoImagem(String? caminhoImagem) {
    if (caminhoImagem == null || caminhoImagem.isEmpty) return null;
    final File arquivo = File(caminhoImagem);
    return arquivo.existsSync() ? arquivo : null;
  }
}
