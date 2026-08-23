using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SPORTSGURUKUL.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAcademyCoachManagement : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PublicUserId",
                table: "Users",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql("""
                UPDATE "Users" u
                SET "PublicUserId" = 'SG-USER-' || to_char(x."rn", 'FM000000')
                FROM (
                    SELECT "Id",
                           row_number() OVER (ORDER BY "CreatedAt", "Id") AS "rn"
                    FROM "Users"
                ) x
                WHERE u."Id" = x."Id";
                """);

            migrationBuilder.CreateTable(
                name: "Coaches",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Coaches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Coaches_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AcademyCoaches",
                columns: table => new
                {
                    AcademyId = table.Column<Guid>(type: "uuid", nullable: false),
                    CoachId = table.Column<Guid>(type: "uuid", nullable: false),
                    BranchId = table.Column<Guid>(type: "uuid", nullable: true),
                    AssignedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AcademyCoaches", x => new { x.AcademyId, x.CoachId });
                    table.ForeignKey(
                        name: "FK_AcademyCoaches_Academies_AcademyId",
                        column: x => x.AcademyId,
                        principalTable: "Academies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AcademyCoaches_AcademyBranches_BranchId",
                        column: x => x.BranchId,
                        principalTable: "AcademyBranches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AcademyCoaches_Coaches_CoachId",
                        column: x => x.CoachId,
                        principalTable: "Coaches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "CoachSports",
                columns: table => new
                {
                    CoachId = table.Column<Guid>(type: "uuid", nullable: false),
                    SportId = table.Column<Guid>(type: "uuid", nullable: false),
                    Specialization = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CoachSports", x => new { x.CoachId, x.SportId });
                    table.ForeignKey(
                        name: "FK_CoachSports_AcademySports_SportId",
                        column: x => x.SportId,
                        principalTable: "AcademySports",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CoachSports_Coaches_CoachId",
                        column: x => x.CoachId,
                        principalTable: "Coaches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_PublicUserId",
                table: "Users",
                column: "PublicUserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AcademyCoaches_BranchId",
                table: "AcademyCoaches",
                column: "BranchId");

            migrationBuilder.CreateIndex(
                name: "IX_AcademyCoaches_CoachId",
                table: "AcademyCoaches",
                column: "CoachId");

            migrationBuilder.CreateIndex(
                name: "IX_Coaches_UserId",
                table: "Coaches",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CoachSports_SportId",
                table: "CoachSports",
                column: "SportId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AcademyCoaches");

            migrationBuilder.DropTable(
                name: "CoachSports");

            migrationBuilder.DropTable(
                name: "Coaches");

            migrationBuilder.DropIndex(
                name: "IX_Users_PublicUserId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PublicUserId",
                table: "Users");
        }
    }
}
