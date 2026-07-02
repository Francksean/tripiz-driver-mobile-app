import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tripiz_driver_mobile_app/home/models/itinerary_model.dart';
import 'package:tripiz_driver_mobile_app/home/repositories/itinerary_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ItineraryRepository _repository;

  HomeCubit({ItineraryRepository? repository})
      : _repository = repository ?? ItineraryRepository(),
        super(HomeInitial());

  Future<void> loadTodayItineraries() async {
    emit(HomeLoading());
    try {
      final itineraries = await _repository.getTodayItineraries();
      emit(HomeLoaded(itineraries));
    } catch (e) {
      emit(HomeError("Erreur lors du chargement des itinéraires"));
    }
  }
}