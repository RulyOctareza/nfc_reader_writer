import 'package:go_router/go_router.dart';
import 'package:nfc_reader_writer/data/repositories/nfc_repository_impl.dart';
import 'package:nfc_reader_writer/data/services/nfc_service.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/format_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/read_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/write_nfc_usecase.dart';
import 'package:nfc_reader_writer/presentation/home/home_screen.dart';
import 'package:nfc_reader_writer/presentation/read/read_nfc_screen.dart';
import 'package:nfc_reader_writer/presentation/read/read_nfc_viewmodel.dart';
import 'package:nfc_reader_writer/presentation/write/write_nfc_screen.dart';
import 'package:nfc_reader_writer/presentation/write/write_nfc_viewmodel.dart';

/// Konfigurasi router dan dependency injection aplikasi.
///
/// Manual DI dilakukan di sini: service → repository → use cases → viewmodel.
/// Setiap navigasi ke /read dan /write membuat instance ViewModel baru.
GoRouter buildAppRouter() {
  // ── Dependency Graph ─────────────────────────────────────────────────────
  final nfcService = NfcService();
  final nfcRepository = NfcRepositoryImpl(nfcService);
  final checkNfcAvailabilityUseCase = CheckNfcAvailabilityUseCase(
    nfcRepository,
  );
  final readNfcUseCase = ReadNfcUseCase(nfcRepository);
  final writeNfcUseCase = WriteNfcUseCase(nfcRepository);
  final formatNfcUseCase = FormatNfcUseCase(nfcRepository);

  // ── Routes ───────────────────────────────────────────────────────────────
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/read',
        builder: (context, state) => ReadNfcScreen(
          viewModel: ReadNfcViewModel(
            readNfcUseCase: readNfcUseCase,
            checkNfcAvailabilityUseCase: checkNfcAvailabilityUseCase,
          ),
        ),
      ),
      GoRoute(
        path: '/write',
        builder: (context, state) => WriteNfcScreen(
          viewModel: WriteNfcViewModel(
            writeNfcUseCase: writeNfcUseCase,
            formatNfcUseCase: formatNfcUseCase,
            checkNfcAvailabilityUseCase: checkNfcAvailabilityUseCase,
          ),
        ),
      ),
    ],
  );
}
