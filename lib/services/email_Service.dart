import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:eventify/models/Event.dart';

class EmailService {
  final String smtpEmail;
  final String smtpPassword;

  EmailService({required this.smtpEmail, required this.smtpPassword});

  Future<File?> generateFilteredPdf(BuildContext context, List<Event> events,
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
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Filtered Events List',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color:
                    PdfColor.fromInt(0xFF4CAF50), 
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(
                thickness: 1,
                color: PdfColor.fromInt(0xFF9E9E9E)), 
            pw.SizedBox(height: 10),
            ...events.map(
              (event) => pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 5),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFE0E0E0), 
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      event.title,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Category: ${event.category}', 
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Date: ${event.start_time}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFF9E9E9E)),
            pw.Text(
              'Total events: ${events.length}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF4CAF50),
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
      BuildContext context, List<Event> events, String recipientEmail) async {
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
