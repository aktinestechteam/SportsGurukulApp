using SPORTSGURUKUL.Application.Batches.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Batches.Common;

public static class BatchResponseMapper
{
    public static BatchResponse Map(Batch batch)
    {
        return new BatchResponse
        {
            BatchId = batch.Id,
            AcademyId = batch.AcademyId,
            Name = batch.Name,
            Description = batch.Description,
            SportId = batch.SportId,
            SportName = batch.Sport?.Name,
            StartDate = batch.StartDate,
            EndDate = batch.EndDate,
            CreatedAt = batch.CreatedAt,
            UpdatedAt = batch.UpdatedAt,
            Slots = batch.Slots
                .OrderBy(s => s.StartTime)
                .Select(s => new BatchScheduleSlotResponse
                {
                    SlotId = s.Id,
                    StartTime = s.StartTime,
                    EndTime = s.EndTime,
                    Location = s.Location,
                })
                .ToList(),
            Coaches = batch.CoachAssociations
                .Select(bc => new BatchCoachResponse
                {
                    CoachId = bc.CoachId,
                    FirstName = bc.Coach.User.FirstName,
                    LastName = bc.Coach.User.LastName,
                    Specialization = bc.Coach.Sports
                        .FirstOrDefault(cs => cs.SportId == batch.SportId)
                        ?.Specialization,
                    AssignedAt = bc.AssignedAt,
                })
                .ToList(),
            Athletes = batch.AthleteAssociations
                .Select(ba => new BatchAthleteResponse
                {
                    AthleteId = ba.AthleteId,
                    FirstName = ba.Athlete.User.FirstName,
                    LastName = ba.Athlete.User.LastName,
                    PrimarySport = ba.Athlete.Sports
                        .FirstOrDefault(as2 => as2.IsPrimary)
                        ?.Sport?.Name,
                    AssignedAt = ba.AssignedAt,
                })
                .ToList(),
        };
    }
}
