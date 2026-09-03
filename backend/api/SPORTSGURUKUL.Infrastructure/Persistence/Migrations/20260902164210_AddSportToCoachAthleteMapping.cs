using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SPORTSGURUKUL.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSportToCoachAthleteMapping : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // The coach-athlete mapping is now per sport (SportId required and
            // part of the primary key). Legacy mappings carried no sport, so
            // they are cleared here; coaches/athletes must be re-assigned per
            // sport through the updated academy UI.
            migrationBuilder.Sql("DELETE FROM \"CoachAthletes\";");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CoachAthletes",
                table: "CoachAthletes");

            migrationBuilder.AddColumn<Guid>(
                name: "SportId",
                table: "CoachAthletes",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddPrimaryKey(
                name: "PK_CoachAthletes",
                table: "CoachAthletes",
                columns: new[] { "CoachId", "AthleteId", "SportId", "AcademyId" });

            migrationBuilder.CreateIndex(
                name: "IX_CoachAthletes_SportId",
                table: "CoachAthletes",
                column: "SportId");

            migrationBuilder.AddForeignKey(
                name: "FK_CoachAthletes_AcademySports_SportId",
                table: "CoachAthletes",
                column: "SportId",
                principalTable: "AcademySports",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CoachAthletes_AcademySports_SportId",
                table: "CoachAthletes");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CoachAthletes",
                table: "CoachAthletes");

            migrationBuilder.DropIndex(
                name: "IX_CoachAthletes_SportId",
                table: "CoachAthletes");

            migrationBuilder.DropColumn(
                name: "SportId",
                table: "CoachAthletes");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CoachAthletes",
                table: "CoachAthletes",
                columns: new[] { "CoachId", "AthleteId", "AcademyId" });
        }
    }
}
