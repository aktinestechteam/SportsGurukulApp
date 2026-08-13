using MediatR;
using SPORTSGURUKUL.Application.Academies.Common;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Academies.Queries;

public sealed record GetAcademyQuery(Guid AcademyId) : IRequest<ApiResponse<AcademyResponse>>;

public sealed class GetAcademyQueryHandler : IRequestHandler<GetAcademyQuery, ApiResponse<AcademyResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademyQueryHandler(
        IAcademyRepository academyRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<AcademyResponse>> Handle(
        GetAcademyQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view an academy.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
            query.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        return ApiResponse<AcademyResponse>.Ok(
            AcademyResponseMapper.Map(academy),
            "Academy retrieved successfully.");
    }
}
