// This is the Finance Controller
// It manages all finance, sponsor, and ticket data for a selected event
// Screens call methods here and this controller talks to FirestoreService

import 'package:get/get.dart';
import 'package:club_management_app/models/finance_model.dart';
import 'package:club_management_app/models/sponsor_model.dart';
import 'package:club_management_app/models/ticket_model.dart';
import 'package:club_management_app/services/firestore_service.dart';

class FinanceController extends GetxController {

  // Our database helper
  final FirestoreService _firestoreService = FirestoreService();

  // The finance record for the current event — nullable because it may not exist yet
  final Rx<FinanceModel?> finance = Rx<FinanceModel?>(null);

  // List of all sponsors for the current event
  final RxList<SponsorModel> sponsors = <SponsorModel>[].obs;

  // The ticket record for the current event — nullable
  final Rx<TicketModel?> ticket = Rx<TicketModel?>(null);

  // Loading state — true means show spinner
  final RxBool isLoading = false.obs;

  // -------------------------------------------------------
  // LOAD ALL FINANCE DATA FOR AN EVENT
  // Call this when opening the Finance Detail screen
  // It loads finance, sponsors, and ticket all at once
  // -------------------------------------------------------
  Future<void> loadFinanceData(String eventId) async {
    try {
      isLoading.value = true;

      // Load all three in parallel using Future.wait
      // This is faster than loading them one by one
      final results = await Future.wait([
        _firestoreService.getFinance(eventId),
        _firestoreService.getSponsors(eventId),
        _firestoreService.getTicket(eventId),
      ]);

      // Save each result to its reactive variable
      finance.value = results[0] as FinanceModel?;
      sponsors.assignAll(results[1] as List<SponsorModel>);
      ticket.value = results[2] as TicketModel?;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load finance data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // SAVE OR UPDATE FINANCE RECORD
  // If finance record exists — update it
  // If it does not exist yet — create it fresh
  // -------------------------------------------------------
  Future<void> saveFinance(String eventId, FinanceModel financeData) async {
    try {
      isLoading.value = true;

      if (finance.value == null) {
        // No finance record exists yet — add a new one
        await _firestoreService.addFinance(eventId, financeData);
      } else {
        // Finance record already exists — update it
        await _firestoreService.updateFinance(
          eventId,
          finance.value!.id,
          financeData.toJson(),
        );
      }

      // Reload the data so the screen shows updated values
      await loadFinanceData(eventId);

      Get.snackbar(
        'Success',
        'Finance details saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Go back to the finance detail screen
      Get.back();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save finance: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // ADD A SPONSOR
  // -------------------------------------------------------
  Future<void> addSponsor(String eventId, SponsorModel sponsor) async {
    try {
      isLoading.value = true;

      await _firestoreService.addSponsor(eventId, sponsor);

      // Reload sponsors list after adding
      final updatedSponsors = await _firestoreService.getSponsors(eventId);
      sponsors.assignAll(updatedSponsors);

      Get.snackbar(
        'Success',
        'Sponsor added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not add sponsor: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // DELETE A SPONSOR
  // -------------------------------------------------------
  Future<void> deleteSponsor(String eventId, String sponsorId) async {
    try {
      await _firestoreService.deleteSponsor(eventId, sponsorId);

      // Remove from local list immediately without reloading
      sponsors.removeWhere((s) => s.id == sponsorId);

      Get.snackbar(
        'Success',
        'Sponsor removed',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not remove sponsor: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------------------------------------
  // SAVE OR UPDATE TICKET RECORD
  // -------------------------------------------------------
  Future<void> saveTicket(String eventId, TicketModel ticketData) async {
    try {
      isLoading.value = true;

      if (ticket.value == null) {
        // No ticket record yet — create one
        await _firestoreService.addTicket(eventId, ticketData);
      } else {
        // Ticket record exists — update it
        await _firestoreService.updateTicket(
          eventId,
          ticket.value!.id,
          ticketData.toJson(),
        );
      }

      // Reload ticket data
      ticket.value = await _firestoreService.getTicket(eventId);

      Get.snackbar(
        'Success',
        'Ticket details saved',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save ticket info: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------
  // CLOSE THE BUDGET FOR AN EVENT
  // Once closed, it is marked as finalized
  // -------------------------------------------------------
  Future<void> closeBudget(String eventId) async {
    try {
      await _firestoreService.closeBudget(eventId);

      Get.snackbar(
        'Budget Closed',
        'The budget for this event has been finalized',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not close budget: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------------------------------------
  // GETTER — Total income for the event
  // Income = sponsorship money + ticket revenue
  // -------------------------------------------------------
  double get totalIncome {
    final sponsorMoney = finance.value?.totalSponsorship ?? 0;
    final ticketMoney = ticket.value?.totalRevenue ?? 0;
    return sponsorMoney + ticketMoney;
  }

// -------------------------------------------------------
  // GETTER — Remaining balance
  // How much money is left = total income - total expenses
  // -------------------------------------------------------
  double get remainingBalance {
    final income = totalIncome;
    final expenses = finance.value?.totalExpenses ?? 0;
    return income - expenses;
  }
}