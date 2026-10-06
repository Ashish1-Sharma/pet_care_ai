import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../config/api.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;

  AuthService(this._apiService)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: AppConfig.googleServerClientId,
        );

  Future<Map<String, dynamic>?> loginWithGoogle() async {
    print('DEBUG: AuthService.loginWithGoogle() started.');
    print('DEBUG: Using Google Server Client ID: ${AppConfig.googleServerClientId}');
    try {
      print('DEBUG: Triggering _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('DEBUG: _googleSignIn.signIn() returned null (User likely cancelled the sign-in flow).');
        return null;
      }

      print('DEBUG: Google User signed in successfully.');
      print('DEBUG: Google User Display Name: ${googleUser.displayName}');
      print('DEBUG: Google User Email: ${googleUser.email}');
      print('DEBUG: Google User ID: ${googleUser.id}');

      print('DEBUG: Fetching Google Authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('DEBUG: Google Authentication fetched successfully.');
      print('DEBUG: ID Token length: ${idToken?.length ?? 0}');
      print('DEBUG: Access Token length: ${accessToken?.length ?? 0}');

      if (idToken == null || idToken.isEmpty) {
        print('DEBUG: ERROR - Obtained ID Token is null or empty.');
        throw 'Failed to obtain Google ID Token.';
      }

      print('DEBUG: Sending ID Token to backend server at endpoint: ${ApiEndpoints.googleLogin}');
      final response = await _apiService.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken},
      );

      print('DEBUG: Backend server response received. Status code: ${response.statusCode}');
      final responseData = response.data;

      if (responseData == null || responseData['token'] == null || responseData['user'] == null) {
        print('DEBUG: ERROR - Backend response is missing token or user data.');
        throw 'Login failed on backend server.';
      }

      final String jwtToken = responseData['token'];
      final UserModel user = UserModel.fromJson(responseData['user']);
      print('DEBUG: Successfully parsed JWT Token and UserModel.');
      print('DEBUG: User details: ${user.name} (${user.email})');

      print('DEBUG: Disconnecting Google Sign-in to reset state for subsequent attempts...');
      await _googleSignIn.disconnect().catchError((error) {
        print('DEBUG: Warning - Disconnect failed: $error');
        return null;
      });

      return {
        'token': jwtToken,
        'user': user,
        'isNewUser': responseData['isNewUser'] == true,
      };
    } catch (e, stackTrace) {
      print('DEBUG: EXCEPTION caught in loginWithGoogle():');
      print('DEBUG: Exception details: $e');
      print('DEBUG: Stacktrace:\n$stackTrace');
      
      print('DEBUG: Disconnecting Google Sign-in on failure...');
      await _googleSignIn.disconnect().catchError((error) {
        print('DEBUG: Warning - Disconnect on failure failed: $error');
        return null;
      });
      rethrow;
    }
  }

  Future<void> signOut() async {
    // We already disconnected, but can call signOut just in case
    await _googleSignIn.signOut().catchError((_) => null);
  }
}
