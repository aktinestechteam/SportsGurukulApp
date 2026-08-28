using MediatR;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Athletes.Queries;

public sealed record GetAthleteProfileQuery
    : IRequest<ApiResponse<AthleteProfileResponse>>;

public sealed class GetAthleteProfileQueryHandler
    : IRequestHandler<GetAthleteProfileQuery, ApiResponse<AthleteProfileResponse>>
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IAthleteRepository _athleteRepository;
    private readonly IBatchRepository _batchRepository;

    public GetAthleteProfileQueryHandler(
        ICurrentUserService currentUserService,
        IAthleteRepository athleteRepository,
        IBatchRepository batchRepository)
    {
        _currentUserService = currentUserService;
        _athleteRepository = athleteRepository;
        _batchRepository = batchRepository;
    }

    public async Task<ApiResponse<AthleteProfileResponse>> Handle(
        GetAthleteProfileQuery request,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.NotFound("Athlete profile not found.");

        var batches = await _batchRepository.GetByAthleteAsync(athlete.Id, cancellationToken);

        var response = new AthleteProfileResponse
        {
            AthleteId = athlete.Id.ToString(),
            FirstName = athlete.User.FirstName,
            LastName = athlete.User.LastName,
            Email = athlete.User.Email,
            Sports = athlete.Sports.Select(s => new AthleteProfileSport
            {
                SportId = s.SportId,
                Name = s.Sport.Name
            }).ToList(),
            Academies = athlete.AcademyAssociations.Select(aa => new AthleteProfileAcademy
            {
                AcademyId = aa.AcademyId.ToString(),
                Name = aa.Academy.Name
            }).ToList(),
            Batches = batches.Select(b => new AthleteProfileBatch
            {
                BatchId = b.Id.ToString(),
                Name = b.Name,
                AcademyId = b.AcademyId.ToString(),
                AcademyName = b.Academy.Name,
                SportName = b.Sport?.Name,
                StartDate = b.StartDate,
                EndDate = b.EndDate,
                Slots = b.Slots.Select(s => new AthleteProfileBatchSlot
                {
                    StartTime = s.StartTime.ToString("HH:mm"),
                    EndTime = s.EndTime.ToString("HH:mm"),
                    Location = s.Location
                }).ToList(),
                Coaches = b.CoachAssociations.Select(bc => new AthleteProfileCoach
                {
                    CoachId = bc.CoachId.ToString(),
                    FirstName = bc.Coach.User.FirstName,
                    LastName = bc.Coach.User.LastName
                }).ToList()
            }).ToList()
        };

        return ApiResponse<AthleteProfileResponse>.Ok(response, "Athlete profile retrieved successfully.");
    }
}