import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../data/models/project_model.dart';

class ExportScreen extends StatelessWidget {
  final ProjectModel project;

  const ExportScreen({super.key, required this.project});

  Future<void> _exportCSV(BuildContext context) async {
    List<List<dynamic>> rows = [
      ['Type', 'Name', 'Latitude', 'Longitude', 'Altitude', 'Accuracy', 'Description', 'Mode', 'Timestamp', 'Length_m', 'Area_m2', 'Perimeter_m']
    ];

    for (var point in project.points) {
      rows.add(['Point', point.name, point.latitude, point.longitude, point.altitude, point.accuracy, point.description, point.collectionMode, point.timestamp.toIso8601String(), '', '', '']);
    }
    for (var line in project.lines) {
      rows.add(['Line', line.name, '', '', '', '', '', '', '', line.length.toStringAsFixed(3), '', '']);
      for (var p in line.points) {
        rows.add(['LinePoint', p.name, p.latitude, p.longitude, p.altitude, p.accuracy, '', '', '', '', '', '']);
      }
    }
    for (var poly in project.polygons) {
      rows.add(['Polygon', poly.name, '', '', '', '', '', '', '', '', poly.area.toStringAsFixed(3), poly.perimeter.toStringAsFixed(3)]);
      for (var p in poly.points) {
        rows.add(['PolyPoint', p.name, p.latitude, p.longitude, p.altitude, p.accuracy, '', '', '', '', '', '']);
      }
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${project.name}_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Geo Master CSV Export');
  }

  Future<void> _exportKML(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"><Document>');
    buffer.writeln('<name>${_esc(project.name)}</name>');

    for (var point in project.points) {
      buffer.writeln('<Placemark><name>${_esc(point.name)}</name><description>${_esc(point.description)}</description>');
      buffer.writeln('<Point><coordinates>${point.longitude},${point.latitude},${point.altitude}</coordinates></Point></Placemark>');
    }
    for (var line in project.lines) {
      buffer.writeln('<Placemark><name>${_esc(line.name)}</name><LineString><coordinates>');
      for (var p in line.points) { buffer.write('${p.longitude},${p.latitude},${p.altitude} '); }
      buffer.writeln('</coordinates></LineString></Placemark>');
    }
    for (var poly in project.polygons) {
      buffer.writeln('<Placemark><name>${_esc(poly.name)}</name><Polygon><outerBoundaryIs><LinearRing><coordinates>');
      for (var p in poly.points) { buffer.write('${p.longitude},${p.latitude},${p.altitude} '); }
      if (poly.points.isNotEmpty) {
        final f = poly.points.first;
        buffer.write('${f.longitude},${f.latitude},${f.altitude}');
      }
      buffer.writeln('</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>');
    }
    buffer.writeln('</Document></kml>');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${project.name}.kml');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Geo Master KML');
  }

  Future<void> _exportGPX(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Geo Master" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('<metadata><name>${_esc(project.name)}</name></metadata>');
    for (var point in project.points) {
      buffer.writeln('<wpt lat="${point.latitude}" lon="${point.longitude}"><ele>${point.altitude}</ele><name>${_esc(point.name)}</name><desc>${_esc(point.description)}</desc><time>${point.timestamp.toUtc().toIso8601String()}</time></wpt>');
    }
    for (var line in project.lines) {
      buffer.writeln('<trk><name>${_esc(line.name)}</name><trkseg>');
      for (var p in line.points) {
        buffer.writeln('<trkpt lat="${p.latitude}" lon="${p.longitude}"><ele>${p.altitude}</ele></trkpt>');
      }
      buffer.writeln('</trkseg></trk>');
    }
    buffer.writeln('</gpx>');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${project.name}.gpx');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Geo Master GPX');
  }

  Future<void> _exportDXF(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('0\nSECTION\n2\nHEADER\n0\nENDSEC\n0\nSECTION\n2\nTABLES\n0\nENDSEC\n0\nSECTION\n2\nBLOCKS\n0\nENDSEC\n0\nSECTION\n2\nENTITIES');

    for (var point in project.points) {
      buffer.writeln('0\nPOINT\n8\nPOINTS\n10\n${point.longitude}\n20\n${point.latitude}\n30\n${point.altitude}');
    }
    for (var line in project.lines) {
      for (int i = 0; i < line.points.length - 1; i++) {
        final p1 = line.points[i];
        final p2 = line.points[i + 1];
        buffer.writeln('0\nLINE\n8\nLINES\n10\n${p1.longitude}\n20\n${p1.latitude}\n30\n${p1.altitude}\n11\n${p2.longitude}\n21\n${p2.latitude}\n31\n${p2.altitude}');
      }
    }
    for (var poly in project.polygons) {
      buffer.writeln('0\nPOLYLINE\n8\nPOLYGONS\n66\n1\n70\n1');
      for (var p in poly.points) {
        buffer.writeln('0\nVERTEX\n8\nPOLYGONS\n10\n${p.longitude}\n20\n${p.latitude}\n30\n${p.altitude}');
      }
      buffer.writeln('0\nSEQEND');
    }
    buffer.writeln('0\nENDSEC\n0\nEOF');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${project.name}.dxf');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Geo Master DXF');
  }

  String _esc(String t) => t.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('export'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(Icons.table_chart, Colors.green, 'CSV', 'export_csv_desc'.tr(), () => _exportCSV(context)),
          _tile(Icons.public, Colors.blue, 'KML', 'export_kml_desc'.tr(), () => _exportKML(context)),
          _tile(Icons.route, Colors.orange, 'GPX', 'export_gpx_desc'.tr(), () => _exportGPX(context)),
          _tile(Icons.architecture, Colors.purple, 'DXF', 'export_dxf_desc'.tr(), () => _exportDXF(context)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.share),
        onTap: onTap,
      ),
    );
  }
}
