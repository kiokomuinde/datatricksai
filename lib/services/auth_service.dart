import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // STREAMS & GETTERS
  // ---------------------------------------------------------------------------

  // Listen to auth state changes (User logged in vs logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of the current user's role/data from Firestore
  // This helps the UI know immediately if the role changes
  Stream<DocumentSnapshot?> get currentUserDataStream {
    if (_auth.currentUser == null) return Stream.value(null);
    return _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots();
  }

  // ---------------------------------------------------------------------------
  // AUTH ACTIONS
  // ---------------------------------------------------------------------------

  // Sign In with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      // Trigger the Authentication Flow (Popup is better for Web)
      UserCredential result = await _auth.signInWithPopup(googleProvider);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email & Password
  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Up with Email & Password
  // Note: We also update the Display Name here for convenience
  Future<User?> signUp({
    required String email, 
    required String password, 
    required String name
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      User? user = result.user;
      
      // Update the user's display name in Firebase Auth immediately
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload(); // Reload to ensure the name is active
      }
      
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // DATABASE SYNC (THE SECURITY LOCK)
  // ---------------------------------------------------------------------------

  /// Saves the user's role to Firestore. 
  /// This is called immediately after Login/Signup in AuthPage.
  Future<void> syncUserRole(User user, {required String role, String? name}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    
    // We use SetOptions(merge: true) so we don't accidentally wipe out 
    // other data if we add more fields later.
    await userRef.set({
      'email': user.email,
      'role': role, // 'admin' or 'applicant'
      'uid': user.uid,
      'lastLogin': FieldValue.serverTimestamp(),
      if (name != null) 'displayName': name,
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  // Helper to make error messages user-friendly
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'credential-already-in-use':
        return 'This email is already associated with a different account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console.';
      case 'popup-closed-by-user':
        return 'Sign-in cancelled by user.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An error occurred (${e.code}). Please try again.';
    }
  }
}