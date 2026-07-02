import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tripiz_driver_mobile_app/common/constants/app_colors.dart';
import 'package:tripiz_driver_mobile_app/common/constants/font_sizes.dart';
import 'package:tripiz_driver_mobile_app/common/utils/custom_date_utils.dart';
import 'package:tripiz_driver_mobile_app/home/components/itinerary_card.dart';
import 'package:tripiz_driver_mobile_app/home/cubits/home_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit();
    _homeCubit.loadTodayItineraries();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: Padding(
        padding: EdgeInsets.only(
          left: 15.0,
          right: 15.0,
          top: kToolbarHeight + 40,
        ),
        child: RefreshIndicator(
          onRefresh: () => _homeCubit.loadTodayItineraries(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildItineraryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Itinéraires du jour",
            style: TextStyle(
              fontSize: FontSizes.upperExtra,
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CustomDateUtils.formatTodayDate(),
            style: TextStyle(
              fontSize: FontSizes.large,
              color: AppColors.vantablack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryList() {
    return Expanded(
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return _buildShimmerList();
          } else if (state is HomeError) {
            return Center(child: Text(state.message));
          } else if (state is HomeLoaded) {
            if (state.itineraries.isEmpty) {
              return Center(
                child: Text(
                  "Aucun itinéraire prévu aujourd'hui",
                  style: TextStyle(
                    fontSize: FontSizes.large,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: state.itineraries.length,
              itemBuilder: (context, index) {
                final itinerary = state.itineraries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItineraryCard(itinerary: itinerary),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DottedLine(
                        direction: Axis.horizontal,
                        lineLength: double.infinity,
                        lineThickness: 1.0,
                        dashLength: 4.0,
                        dashColor: AppColors.background,
                        dashGapLength: 4.0,
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return _buildShimmerList();
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.background,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}