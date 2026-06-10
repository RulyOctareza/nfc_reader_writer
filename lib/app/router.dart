import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_verifier.dart';
import 'package:nfc_reader_writer/data/repositories/nfc_repository_impl.dart';
import 'package:nfc_reader_writer/data/services/nfc_service.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/format_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/read_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/write_nfc_usecase.dart';
import 'package:nfc_reader_writer/presentation/home/home_screen.dart';
import 'package:nfc_reader_writer/presentation/kencana/read_kencana_nfc_screen.dart';
import 'package:nfc_reader_writer/presentation/kencana/read_kencana_nfc_viewmodel.dart';
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
      GoRoute(
        path: '/read-kencana',
        builder: (context, state) => const _ReadKencanaRoute(),
      ),
    ],
  );
}

/// Memuat verifier Ed25519 dari asset sebelum menampilkan layar Kencana.
class _ReadKencanaRoute extends StatelessWidget {
  const _ReadKencanaRoute();

  static final Future<ReadKencanaNfcViewModel> _viewModelFuture =
      _createViewModel();

  static Future<ReadKencanaNfcViewModel> _createViewModel() async {
    final verifier = await KencanaNfcVerifier.fromAsset();
    final service = NfcService(kencanaVerifier: verifier);
    final repository = NfcRepositoryImpl(service);
    return ReadKencanaNfcViewModel(
      readNfcUseCase: ReadNfcUseCase(repository),
      checkNfcAvailabilityUseCase: CheckNfcAvailabilityUseCase(repository),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ReadKencanaNfcViewModel>(
    future: _viewModelFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Baca Kartu Kencana')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal memuat kunci verifikasi:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return ReadKencanaNfcScreen(viewModel: snapshot.data!);
    },
  );
}
