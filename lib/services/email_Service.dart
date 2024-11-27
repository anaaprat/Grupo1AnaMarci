import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpEmail;
  final String smtpPassword;

  EmailService({required this.smtpEmail, required this.smtpPassword});

  /// Genera un archivo PDF basado en la lista de eventos.
  Future<File?> generateFilteredPdf(BuildContext context, List<dynamic> events,
      {bool openAfterGeneration = false, bool saveToDownloads = true}) async {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No hay eventos que coincidan con los filtros seleccionados.'),
        ),
      );
      return null; 
    }

    final pdf = pw.Document();

    // Generar el contenido del PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Listado de Eventos Filtrados',
                style: pw.TextStyle(fontSize: 20)),
            pw.Divider(),
            ...events.map(
              (event) => pw.Text(
                '${event.title} - ${event.category} - ${event.start_time}',
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );

    File? file;

    // Si se especifica guardar en Descargas
    if (saveToDownloads) {
      if (await Permission.storage.request().isGranted) {
        final directory =
            Directory('/storage/emulated/0/Download'); // Carpeta de Descargas
        if (!directory.existsSync()) {
          directory.createSync(); // Crear la carpeta si no existe
        }

        // Generar un nombre único para el archivo
        String getUniqueFilePath(String baseName, String extension) {
          int counter = 1;
          String filePath = '${directory.path}/$baseName$extension';
          while (File(filePath).existsSync()) {
            filePath = '${directory.path}/$baseName($counter)$extension';
            counter++;
          }
          return filePath;
        }

        // Asignar un nombre único al archivo
        final filePath = getUniqueFilePath('eventos_filtrados', '.pdf');
        file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF guardado en Descargas: $filePath')));

        if (openAfterGeneration) {
          OpenFile.open(file.path); // Abrir el archivo si se permite
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permiso para acceder al almacenamiento denegado.'),
          ),
        );
        return null;
      }
    } else {
      // Si no se especifica guardar, solo crear un archivo temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/eventos_filtrados_temp.pdf';
      file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    }

    return file; // Retorna el archivo generado
  }

  /// Envía un correo con el archivo PDF generado como adjunto.
  Future<void> sendFilteredPdfEmail(
      BuildContext context, List<dynamic> events, String recipientEmail) async {
    try {
      // Generar el PDF sin guardar en Descargas
      final pdfFile = await generateFilteredPdf(
        context,
        events,
        openAfterGeneration: false, // No abrir el archivo
        saveToDownloads: false, // No guardar en Descargas
      );
      if (pdfFile == null) return; // Detener si no se genera el archivo

      // Configurar los detalles del correo
      final smtpServer = gmail(smtpEmail, smtpPassword);

      final message = Message()
        ..from = Address(smtpEmail, 'Eventify Service')
        ..recipients.add(recipientEmail) // Correo del destinatario
        ..subject = 'Eventos Filtrados'
        ..text =
            'Adjunto encontrarás un PDF con los eventos filtrados según tus selecciones.'
        ..attachments = [
          FileAttachment(pdfFile) // Adjuntar el archivo PDF generado
            ..location = Location.attachment
        ];

      // Enviar el correo
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: $sendReport');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correo enviado con éxito.')),
      );
    } catch (e) {
      print('Error al enviar el correo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el correo.')),
      );
    }
  }
}
