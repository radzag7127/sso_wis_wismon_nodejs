import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/get_payment_history_usecase.dart';
import '../../features/payment/domain/usecases/get_payment_summary_usecase.dart';
import '../../features/payment/domain/usecases/get_transaction_detail_usecase.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<RouteObserver<PageRoute>>(() => RouteObserver());

  // Auth Feature
  // Data sources & repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiService: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
    ),
  );

  // Payment Feature
  // Data sources & repositories
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(apiService: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPaymentHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionDetailUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => PaymentBloc(
      getPaymentHistoryUseCase: sl(),
      getPaymentSummaryUseCase: sl(),
      getTransactionDetailUseCase: sl(),
    ),
  );
}
