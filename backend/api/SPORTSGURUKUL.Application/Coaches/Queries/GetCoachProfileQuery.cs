using MediatR;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Coaches.Queries;

public sealed record GetCoachProfileQuery
    : IRequest<ApiResponse<CoachProfileResponse>>;

public sealed class GetCoachProfileQueryHandler
    : IRequestHandler<GetCoachProfileQuery, ApiResponse<CoachProfileResponse>>
{
    private readonly ICurrentUserService _currentUserService;
    private readonly ICoachRepository _coachRepository;
    private readonly IBatchRepository _batchRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;

    public GetCoachProfileQueryHandler(
        ICurrentUserService currentUserService,
        ICoachRepository coachRepository,
        IBatchRepository batchRepository,
        ICoachAthleteRepository coachAthleteRepository)
    {
        _currentUserService = currentUserService;
        _coachRepository = coachRepository;
        _batchRepository = batchRepository;
        _coachAthleteRepository = coachAthleteRepository;
    }

    public async Task<ApiResponse<CoachProfileResponse>> Handle(
        GetCoachProfileQuery request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in.");
        }

        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.NotFound("Coach profile not found.");

        var batches = await _batchRepository.GetByCoachAsync(coach.Id, cancellationToken);
        var athleteMappings = await _coachAthleteRepository.GetByCoachAsync(coach.Id, cancellationToken);

        var response = new CoachProfileResponse
        {
            CoachId = coach.Id.ToString(),
            FirstName = coach.User.FirstName,
            LastName = coach.User.LastName,
            Email = coach.User.Email,
            Academies = coach.AcademyAssociations.Select(ac => new CoachProfileAcademy
            {
                AcademyId = ac.AcademyId.ToString(),
                Name = ac.Academy.Name,
                Sports = coach.Sports
                    .Where(cs => ac.Academy.Sports.Any(s => s.Id == cs.SportId))
                    .Select(cs => new CoachProfileAcademySport
                    {
                        Name = cs.Sport.Name,
                        Specialization = cs.Specialization
                    })
                    .ToList()
            }).ToList(),
            Batches = batches.Select(b => new CoachProfileBatch
            {
                BatchId = b.Id.ToString(),
                Name = b.Name,
                AcademyId = b.AcademyId.ToString(),
                AcademyName = b.Academy.Name,
                SportName = b.Sport?.Name,
                AthletesCount = b.AthleteAssociations.Count,
                Slots = b.Slots.Select(s => new CoachProfileBatchSlot
                {
                    DayOfWeek = (int)s.DayOfWeek,
                    StartTime = s.StartTime.ToString("HH:mm"),
                    EndTime = s.EndTime.ToString("HH:mm"),
                    Location = s.Location
                }).ToList(),
                Coaches = b.CoachAssociations.Select(bc => new CoachProfileBatchPeer
                {
                    CoachId = bc.CoachId.ToString(),
                    FirstName = bc.Coach.User.FirstName,
                    LastName = bc.Coach.User.LastName
                }).ToList(),
                Athletes = b.AthleteAssociations.Select(ba => new CoachProfileBatchAthlete
                {
                    AthleteId = ba.AthleteId.ToString(),
                    FirstName = ba.Athlete.User.FirstName,
                    LastName = ba.Athlete.User.LastName,
                    Sport = ba.Athlete.Sports
                        .OrderByDescending(s => s.IsPrimary)
                        .Select(s => s.Sport.Name)
                        .FirstOrDefault()
                }).ToList()
            }).ToList(),
            Athletes = athleteMappings.Select(cm => new CoachProfileAthlete
            {
                AthleteId = cm.AthleteId.ToString(),
                FirstName = cm.Athlete.User.FirstName,
                LastName = cm.Athlete.User.LastName,
                Sport = cm.Athlete.Sports
                    .OrderByDescending(s => s.IsPrimary)
                    .Select(s => s.Sport.Name)
                    .FirstOrDefault(),
                Email = cm.Athlete.User.Email,
                MobileNumber = cm.Athlete.User.MobileNumber
            }).ToList()
        };

        return ApiResponse<CoachProfileResponse>.Ok(response, "Coach profile retrieved successfully.");
    }
}
