import 'package:sports_gurukul/features/coach/domain/entities/coach.dart';
import 'package:sports_gurukul/features/coach/domain/repositories/coach_repository.dart';
import 'package:sports_gurukul/features/coach/domain/usecases/create_coach.dart';
import 'package:sports_gurukul/features/coach/domain/usecases/delete_coach.dart';
import 'package:sports_gurukul/features/coach/domain/usecases/get_coaches.dart';
import 'package:sports_gurukul/features/coach/domain/usecases/update_coach.dart';
import 'package:sports_gurukul/features/coach/presentation/providers/coach_provider.dart';

class FakeCoachRepository implements CoachRepository {
  FakeCoachRepository({this.coaches = const []});

  List<Coach> coaches;

  int createCoachCalls = 0;
  int updateCoachCalls = 0;
  int deleteCoachCalls = 0;

  @override
  Future<List<Coach>> getCoaches(String academyId) async => coaches;

  @override
  Future<Coach> createCoach(String academyId, CoachRequestInput input) async {
    createCoachCalls++;
    final coach = Coach(
      coachId: 'c${coaches.length + 1}',
      publicUserId: 'SG-COACH-${(100000 + coaches.length + 1)}',
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      mobileNumber: input.mobileNumber,
      academyId: academyId,
      academyName: 'Sports Gurukul Academy',
      branchId: input.branchId,
      branchName: 'Main Campus',
      status: CoachStatus.invited,
      sports: [
        for (final sport in input.sports)
          CoachSport(
            sportId: sport.sportId,
            name: 'Cricket',
            specialization: sport.specialization,
          ),
      ],
      createdAt: DateTime.now().toIso8601String(),
    );
    coaches = [coach, ...coaches];
    return coach;
  }

  @override
  Future<Coach> updateCoach(
    String academyId,
    String coachId,
    CoachRequestInput input,
  ) async {
    updateCoachCalls++;
    final index = coaches.indexWhere((c) => c.coachId == coachId);
    final current = index >= 0 ? coaches[index] : coaches.first;
    final updated = Coach(
      coachId: current.coachId,
      publicUserId: current.publicUserId,
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      mobileNumber: input.mobileNumber,
      academyId: current.academyId,
      academyName: current.academyName,
      branchId: input.branchId,
      branchName: current.branchName,
      status: current.status,
      sports: [
        for (final sport in input.sports)
          CoachSport(
            sportId: sport.sportId,
            name: 'Cricket',
            specialization: sport.specialization,
          ),
      ],
      createdAt: current.createdAt,
    );
    if (index >= 0) {
      coaches = [
        for (var i = 0; i < coaches.length; i++)
          if (i == index) updated else coaches[i],
      ];
    }
    return updated;
  }

  @override
  Future<void> deleteCoach(String academyId, String coachId) async {
    deleteCoachCalls++;
    coaches = coaches.where((c) => c.coachId != coachId).toList();
  }
}

CoachProvider buildCoachProvider({List<Coach> coaches = const []}) {
  final repo = FakeCoachRepository(coaches: coaches);
  return CoachProvider(
    createCoach: CreateCoach(repo),
    getCoaches: GetCoaches(repo),
    updateCoach: UpdateCoach(repo),
    deleteCoach: DeleteCoach(repo),
  );
}
