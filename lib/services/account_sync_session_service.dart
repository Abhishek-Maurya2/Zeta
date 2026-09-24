import 'pomodoro_sync_service.dart';
import 'revision_sync_service.dart';
import 'supabase_sync_service.dart';

/// Stops callbacks and in-memory retries when the active account signs out.
/// Durable retries remain in the account-scoped preferences/SQLite stores.
class AccountSyncSessionService {
  AccountSyncSessionService._();
  static final AccountSyncSessionService instance =
      AccountSyncSessionService._();

  void endSession() {
    SupabaseSyncService().endAccountSession();
    RevisionSyncService().endAccountSession();
    PomodoroSyncService().endAccountSession();
  }
}
