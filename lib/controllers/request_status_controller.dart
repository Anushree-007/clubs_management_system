import 'package:get/get.dart';
import 'package:club_management_app/services/firestore_service.dart';

class RequestStatusController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  
  final RxBool isLoading = false.obs;
  // ✅ FIXED: Non-nullable with initial empty map
  final RxMap<String, dynamic> statusResult = <String, dynamic>{}.obs;

  Future<void> checkStatus(String email) async {
    isLoading.value = true;
    statusResult.clear(); // ✅ Clear instead of setting null
    
    try {
      final request = await _firestoreService.getRequestByEmail(email);
      
      if (request != null) {
        statusResult.value = {
          'status': request['status'],
          'email': request['email'],
          'name': request['name'],
          if (request['status'] == 'approved') 'tempPassword': request['tempPassword'],
          if (request['status'] == 'rejected') 'rejectionReason': request['rejectionReason'],
        };
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not check status: $e');
      statusResult.clear(); // Clear on error too
    } finally {
      isLoading.value = false;
    }
  }
}