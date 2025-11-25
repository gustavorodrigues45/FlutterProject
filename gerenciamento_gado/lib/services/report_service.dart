import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> gerarRelatorioGeral() async {
    final pdf = pw.Document();
    final gados = await _dbHelper.buscarTodosGados();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Relatório de Gado',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Data: ${dateFormat.format(DateTime.now())}'),
          pw.Text('Total de animais: ${gados.length}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Nome', 'Idade (meses)', 'Peso (kg)', 'Sexo', 'Vacinas'],
            data: gados.map((gado) => [
              gado['nome'],
              gado['idade'].toString(),
              gado['peso'].toString(),
              gado['sexo'],
              gado['vacinas'],
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> gerarRelatorioPorPropriedade(String proprietarioId) async {
    final pdf = pw.Document();
    final propriedades = await _dbHelper.buscarPropriedadesPorProprietario(proprietarioId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var propriedade in propriedades) {
      final gados = await _dbHelper.buscarTodosGados();
      final gadosPropriedade = gados.where((g) => g['propriedade_id'] == propriedade['id']).toList();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório - ${propriedade['nome']}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Data: ${dateFormat.format(DateTime.now())}'),
              pw.Text('Total de animais: ${gadosPropriedade.length}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Nome', 'Idade', 'Peso', 'Sexo'],
                data: gadosPropriedade.map((gado) => [
                  gado['nome'],
                  '${gado['idade']} meses',
                  '${gado['peso']} kg',
                  gado['sexo'],
                ]).toList(),
              ),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> gerarRelatorioVacinas() async {
    final pdf = pw.Document();
    final gados = await _dbHelper.buscarTodosGados();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Relatório de Vacinação',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Data: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Nome do Animal', 'Vacinas Aplicadas'],
            data: gados.map((gado) => [
              gado['nome'],
              gado['vacinas'],
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> gerarRelatorioTransferencias(String gadoId) async {
    final pdf = pw.Document();
    final gado = await _dbHelper.buscarGadoPorId(gadoId);
    final transferencias = await _dbHelper.buscarTransferenciasPorGado(gadoId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Histórico de Transferências',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Animal: ${gado?['nome'] ?? 'N/A'}'),
            pw.Text('Data: ${dateFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Origem', 'Destino', 'Observações'],
              data: transferencias.map((t) => [
                DateFormat('dd/MM/yyyy').format(DateTime.parse(t['data_transferencia'])),
                'Prop. ${t['proprietario_origem_id']}',
                'Prop. ${t['proprietario_destino_id']}',
                t['observacoes'] ?? '-',
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> gerarRelatorioPorPeriodo(DateTime inicio, DateTime fim) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    final gadosAtivos = await _dbHelper.buscarGadosAtivos();
    final saidas = await _dbHelper.buscarSaidasPorPeriodo(inicio: inicio, fim: fim);
    final vacinas = await _dbHelper.buscarVacinasPorPeriodo(inicio: inicio, fim: fim);

    final vendas = saidas.where((s) => s['tipo'] == 'venda').length;
    final perdas = saidas.where((s) => s['tipo'] == 'perda').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Relatório por Período', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.Text('Início: ${dateFormat.format(inicio)}'),
          pw.Text('Fim: ${dateFormat.format(fim)}'),
          pw.SizedBox(height: 12),
          pw.Text('Resumo'),
          pw.Bullet(text: 'Animais ativos: ${gadosAtivos.length}'),
          pw.Bullet(text: 'Vendas: $vendas'),
          pw.Bullet(text: 'Perdas: $perdas'),
          pw.Bullet(text: 'Vacinas aplicadas: ${vacinas.length}'),
          pw.SizedBox(height: 16),
          pw.Text('Vacinas aplicadas no período'),
          pw.TableHelper.fromTextArray(
            headers: ['Animal', 'Vacina', 'Data', 'Próxima dose'],
            data: vacinas.map((v) => [
              v['gado_id'],
              v['vacina'],
              dateFormat.format(DateTime.parse(v['data_aplicacao'])),
              v['proxima_dose'] != null ? dateFormat.format(DateTime.parse(v['proxima_dose'])) : '-',
            ]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Saídas no período'),
          pw.TableHelper.fromTextArray(
            headers: ['Animal', 'Tipo', 'Data', 'Observações'],
            data: saidas.map((s) => [
              s['gado_id'],
              (s['tipo'] as String).toUpperCase(),
              dateFormat.format(DateTime.parse(s['data_saida'])),
              s['observacoes'] ?? '-',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
