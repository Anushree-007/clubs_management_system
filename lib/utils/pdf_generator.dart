// This file generates a PDF report for a club
// It uses the 'pdf' package to create a nicely formatted document
// The report includes club info, members, and event history

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // pw = pdf widgets
import 'package:printing/printing.dart'; // For sharing or printing the PDF
import 'package:club_management_app/models/club_model.dart';
import 'package:club_management_app/models/member_model.dart';
import 'package:club_management_app/models/event_model.dart';
import 'package:club_management_app/models/tenure_model.dart';

class PdfGenerator {

  // -------------------------------------------------------
  // GENERATE CLUB REPORT
  // Creates a complete PDF for a club and opens the share dialog
  // -------------------------------------------------------
  static Future<void> generateClubReport({
    required ClubModel club,
    required TenureModel tenure,
    required List<MemberModel> members,
    required List<EventModel> events,
  }) async {

    // Create a new PDF document
    final pdf = pw.Document();

    // Add a page to the document
    pdf.addPage(
      // MultiPage allows the content to flow across multiple pages automatically
      pw.MultiPage(
        // Page size A4
        pageFormat: PdfPageFormat.a4,
        // Margin on all sides
        margin: const pw.EdgeInsets.all(32),

        // Header shown on every page
        header: (context) => _buildHeader(club),

        // Footer shown on every page
        footer: (context) => _buildFooter(context),

        // Main content of the report
        build: (context) => [

          // Club basic info section
          _buildSectionTitle('Club Information'),
          pw.SizedBox(height: 8),
          _buildInfoTable({
            'Club Name': club.name,
            'Short Code': club.shortCode,
            'Domain': club.domain,
            'Status': club.status.toUpperCase(),
            'Description': club.description,
          }),

          pw.SizedBox(height: 20),

          // Faculty in charge section
          _buildSectionTitle('Faculty In Charge'),
          pw.SizedBox(height: 8),
          _buildInfoTable({
            'Name': club.facultyName,
            'Email': club.facultyEmail,
            'Phone': club.facultyPhone,
          }),

          pw.SizedBox(height: 20),

          // Tenure section
          _buildSectionTitle('Current Tenure'),
          pw.SizedBox(height: 8),
          _buildInfoTable({
            'Start Date': _formatDate(tenure.startDate),
            'End Date': tenure.endDate != null
                ? _formatDate(tenure.endDate!)
                : 'Present',
            'Status': tenure.isActive ? 'Active' : 'Inactive',
          }),

          pw.SizedBox(height: 20),

          // Club hierarchy section
          if (tenure.hierarchy.isNotEmpty) ...[
            _buildSectionTitle('Club Hierarchy'),
            pw.SizedBox(height: 8),
            // Build a row for each hierarchy entry
            ...tenure.hierarchy.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${entry['position']}: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(entry['memberName'] ?? ''),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Members section
          _buildSectionTitle('Members (${members.length} total)'),
          pw.SizedBox(height: 8),

          // Members table
          if (members.isEmpty)
            pw.Text('No members added yet')
          else
            pw.TableHelper.fromTextArray(
              // Table header row
              headers: ['Name', 'PRN', 'Position', 'Year', 'Dept'],
              // Table data rows — one row per member
              data: members.map((m) => [
                m.name,
                m.prn,
                m.position,
                'Year ${m.year}',
                m.department,
              ]).toList(),
              // Style the header row
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              // Alternate row colors for readability
              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              // Column widths
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
            ),

          pw.SizedBox(height: 20),

          // Events section
          _buildSectionTitle('Events (${events.length} total)'),
          pw.SizedBox(height: 8),

          if (events.isEmpty)
            pw.Text('No events recorded yet')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Event Name', 'Date', 'Type', 'Attended', 'Budget'],
              data: events.map((e) => [
                e.name,
                _formatDate(e.date),
                e.type,
                e.totalAttendees.toString(),
                e.budgetClosed ? 'Closed' : 'Open',
              ]).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey50,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
            ),
        ],
      ),
    );

    // Open the share/print dialog so user can save or share the PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // -------------------------------------------------------
  // HELPER: Page Header
  // Shown at the top of every page
  // -------------------------------------------------------
  static pw.Widget _buildHeader(ClubModel club) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Club name on the left
          pw.Text(
            club.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // Report label on the right
          pw.Text(
            'Club Report — VIT',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Page Footer
  // Shown at the bottom of every page
  // -------------------------------------------------------
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.blueGrey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Generated date on the left
          pw.Text(
            'Generated on ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          // Page number on the right
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Section Title
  // Bold heading with a colored bottom border
  // -------------------------------------------------------
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue700,
            width: 1.5,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Info Table
  // Shows key-value pairs in a clean table
  // -------------------------------------------------------
  static pw.Widget _buildInfoTable(Map<String, String> data) {
    return pw.Table(
      children: data.entries.map((entry) {
        return pw.TableRow(
          children: [
            // Key on the left
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                entry.key,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ),
            // Value on the right
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(entry.value),
            ),
          ],
        );
      }).toList(),
      columnWidths: {
        // Key column takes 35% of width
        0: const pw.FractionColumnWidth(0.35),
        // Value column takes 65% of width
        1: const pw.FractionColumnWidth(0.65),
      },
    );
  }

  // -------------------------------------------------------
  // HELPER: Format Date
  // -------------------------------------------------------
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}