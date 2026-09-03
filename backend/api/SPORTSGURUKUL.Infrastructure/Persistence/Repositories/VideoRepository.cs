using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Videos.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class VideoRepository : IVideoRepository
{
    private readonly AppDbContext _context;

    public VideoRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<VideoSubmission?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .Include(v => v.Athlete).ThenInclude(a => a.User)
            .Include(v => v.Sport)
            .Include(v => v.Comments).ThenInclude(c => c.Author)
            .Include(v => v.Views)
            .Where(v => v.IsDeleted == false)
            .FirstOrDefaultAsync(v => v.Id == id, ct);

    public Task<List<VideoSubmission>> GetByAthleteIdAsync(Guid athleteId, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .Include(v => v.Athlete).ThenInclude(a => a.User)
            .Include(v => v.Sport)
            .Include(v => v.Comments)
            .Include(v => v.Views)
            .Where(v => v.AthleteId == athleteId && v.IsDeleted == false)
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync(ct);

    public Task<List<VideoSubmission>> GetFeedForCoachAsync(
        Guid coachId, Guid? sportId, Guid? athleteId, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .Include(v => v.Athlete).ThenInclude(a => a.User)
            .Include(v => v.Sport)
            .Include(v => v.Comments)
            .Include(v => v.Views)
            .Where(v => v.IsDeleted == false
                && v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == v.SportId)
                && (sportId == null || v.SportId == sportId)
                && (athleteId == null || v.AthleteId == athleteId))
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync(ct);

    public Task<List<VideoSubmission>> GetFeedForAdminAsync(
        Guid academyId, Guid? coachId, Guid? sportId, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .Include(v => v.Athlete).ThenInclude(a => a.User)
            .Include(v => v.Sport)
            .Include(v => v.Comments)
            .Include(v => v.Views)
            .Where(v => v.IsDeleted == false
                && v.Athlete.AcademyAssociations.Any(aa => aa.AcademyId == academyId)
                && (coachId == null || v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId && ca.AcademyId == academyId))
                && (sportId == null || v.SportId == sportId))
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync(ct);

    public Task<List<VideoComment>> GetCommentsAsync(Guid videoId, CancellationToken ct = default)
        => _context.VideoComments
            .AsNoTracking()
            .Include(c => c.Author)
            .Where(c => c.VideoSubmissionId == videoId && c.IsDeleted == false)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync(ct);

    public Task<bool> HasCoachAccessAsync(Guid coachId, Guid videoId, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .AnyAsync(v => v.Id == videoId
                && v.IsDeleted == false
                && v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == v.SportId), ct);

    public async Task AddAsync(VideoSubmission video, CancellationToken ct = default)
        => await _context.VideoSubmissions.AddAsync(video, ct);

    public async Task AddCommentAsync(VideoComment comment, CancellationToken ct = default)
        => await _context.VideoComments.AddAsync(comment, ct);

    public Task<VideoComment?> GetCommentByIdAsync(Guid commentId, CancellationToken ct = default)
        => _context.VideoComments
            .Include(c => c.Author)
            .FirstOrDefaultAsync(c => c.Id == commentId, ct);

    public async Task<int> SoftDeleteCommentsForVideoAsync(Guid videoId, CancellationToken ct = default)
    {
        var comments = await _context.VideoComments
            .Where(c => c.VideoSubmissionId == videoId && c.IsDeleted == false)
            .ToListAsync(ct);

        foreach (var comment in comments)
        {
            comment.IsDeleted = true;
            comment.Touch();
        }

        return comments.Count;
    }

    public async Task SoftDeleteAsync(Guid videoId, CancellationToken ct = default)
    {
        var video = await _context.VideoSubmissions
            .FirstOrDefaultAsync(v => v.Id == videoId, ct);

        if (video is null)
        {
            return;
        }

        video.IsDeleted = true;
        video.Touch();
    }

    public Task<bool> HasViewedAsync(Guid userId, Guid videoId, CancellationToken ct = default)
        => _context.VideoViews
            .AsNoTracking()
            .AnyAsync(v => v.UserId == userId && v.VideoSubmissionId == videoId, ct);

    public async Task AddViewAsync(VideoView view, CancellationToken ct = default)
        => await _context.VideoViews.AddAsync(view, ct);

    public async Task<int> GetVideoCountForCoachAsync(Guid coachId, CancellationToken ct = default)
        => await _context.VideoSubmissions
            .AsNoTracking()
            .CountAsync(v => v.IsDeleted == false
                && v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == v.SportId), ct);

    public async Task<int> GetUnviewedCountForCoachAsync(Guid coachId, CancellationToken ct = default)
    {
        var coachUserId = await _context.Coaches
            .Where(c => c.Id == coachId)
            .Select(c => c.UserId)
            .FirstOrDefaultAsync(ct);

        return await _context.VideoSubmissions
            .AsNoTracking()
            .CountAsync(v => v.IsDeleted == false
                && v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == v.SportId)
                && !v.Views.Any(vw => vw.UserId == coachUserId), ct);
    }

    public Task<List<VideoSubmission>> GetRecentAssignedVideosForCoachAsync(
        Guid coachId, DateTime since, int limit, CancellationToken ct = default)
        => _context.VideoSubmissions
            .AsNoTracking()
            .Include(v => v.Athlete).ThenInclude(a => a.User)
            .Include(v => v.Sport)
            .Where(v => v.IsDeleted == false
                && v.CreatedAt >= since
                && v.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == v.SportId))
            .OrderByDescending(v => v.CreatedAt)
            .Take(limit)
            .ToListAsync(ct);

    public Task<List<VideoComment>> GetRecentCommentsForCoachAsync(
        Guid coachId, Guid excludingUserId, DateTime since, int limit, CancellationToken ct = default)
        => _context.VideoComments
            .AsNoTracking()
            .Include(c => c.Author)
            .Include(c => c.VideoSubmission).ThenInclude(v => v.Athlete).ThenInclude(a => a.User)
            .Include(c => c.VideoSubmission).ThenInclude(v => v.Sport)
            .Where(c => c.IsDeleted == false
                && c.CreatedAt >= since
                && c.AuthorUserId != excludingUserId
                && c.VideoSubmission.IsDeleted == false
                && c.VideoSubmission.Athlete.CoachMappings.Any(ca => ca.CoachId == coachId
                    && ca.SportId == c.VideoSubmission.SportId))
            .OrderByDescending(c => c.CreatedAt)
            .Take(limit)
            .ToListAsync(ct);

    public Task<List<VideoComment>> GetRecentCommentsForAthleteAsync(
        Guid athleteId, Guid excludingUserId, DateTime since, int limit, CancellationToken ct = default)
        => _context.VideoComments
            .AsNoTracking()
            .Include(c => c.Author)
            .Include(c => c.VideoSubmission)
            .Where(c => c.IsDeleted == false
                && c.CreatedAt >= since
                && c.AuthorUserId != excludingUserId
                && c.VideoSubmission.IsDeleted == false
                && c.VideoSubmission.AthleteId == athleteId)
            .OrderByDescending(c => c.CreatedAt)
            .Take(limit)
            .ToListAsync(ct);
}