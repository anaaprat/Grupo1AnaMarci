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

  Future<File?> generateFilteredPdf(BuildContext context, List<dynamic> events,
      {bool openAfterGeneration = false, bool saveToDownloads = true}) async {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Any events match with the selected filters'),
        ),
      );
      return null;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Filtered events list', style: pw.TextStyle(fontSize: 20)),
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

    if (saveToDownloads) {
      if (await Permission.storage.request().isGranted) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory.createSync();
        }

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
        final filePath = getUniqueFilePath('filtered_events', '.pdf');
        file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('saved PDF: $filePath')));

        if (openAfterGeneration) {
          OpenFile.open(file.path);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not allowed'),
          ),
        );
        return null;
      }
    } else {
      // Si no se especifica guardar, solo crear un archivo temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/filtered_events_temp.pdf';
      file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    }

    return file;
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
      if (pdfFile == null) return;

      final smtpServer = gmail(smtpEmail, smtpPassword);

      final message = Message()
        ..from = Address(smtpEmail, 'Eventify Service')
        ..recipients.add(recipientEmail)
        ..subject = 'Eventos Filtrados'
        ..text =
            'Adjunto encontrarás un PDF con los eventos filtrados según tus selecciones.'
        ..attachments = [
          FileAttachment(pdfFile)..location = Location.attachment
        ];

      // Enviar el correo
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: $sendReport');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sended succesfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email')),
      );
    }
  }
}
