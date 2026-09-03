using MediatR;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetUnviewedCountQuery
    : IRequest<ApiResponse<int>>;

public sealed class GetUnviewedCountQueryHandler
    : IRequestHandler<GetUnviewedCountQuery, ApiResponse<int>>
{
    private readonly ICoachRepository _coachRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetUnviewedCountQueryHandler(
        ICoachRepository coachRepository,
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService)
    {
        _coachRepository = coachRepository;
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<int>> Handle(
        GetUnviewedCountQuery query,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view your unread count.");
        }

        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.Forbidden("Only coaches can view the unread count.");

        var count = await _videoRepository.GetUnviewedCountForCoachAsync(coach.Id, cancellationToken);

        return ApiResponse<int>.Ok(count, "Unread count retrieved successfully.");
    }
}
