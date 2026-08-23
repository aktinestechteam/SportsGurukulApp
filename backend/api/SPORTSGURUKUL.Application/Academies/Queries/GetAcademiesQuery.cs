using MediatR;
using SPORTSGURUKUL.Application.Academies.Common;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Academies.Queries;

public sealed record GetAcademiesQuery : IRequest<ApiResponse<List<AcademyResponse>>>;

public sealed class GetAcademiesQueryHandler : IRequestHandler<GetAcademiesQuery, ApiResponse<List<AcademyResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademiesQueryHandler(
        IAcademyRepository academyRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<AcademyResponse>>> Handle(
        GetAcademiesQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view academies.");
        }

        var academies = await _academyRepository.GetByOwnerAsync(ownerUserId, cancellationToken);

        return ApiResponse<List<AcademyResponse>>.Ok(
            academies.Select(AcademyResponseMapper.Map).ToList(),
            "Academies retrieved successfully.");
    }
}
