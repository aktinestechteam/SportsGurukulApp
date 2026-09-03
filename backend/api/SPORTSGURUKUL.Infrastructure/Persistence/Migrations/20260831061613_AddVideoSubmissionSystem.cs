using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SPORTSGURUKUL.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddVideoSubmissionSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "VideoSubmissions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AthleteId = table.Column<Guid>(type: "uuid", nullable: false),
                    SportId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    S3Key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ThumbnailS3Key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VideoSubmissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VideoSubmissions_AcademySports_SportId",
                        column: x => x.SportId,
                        principalTable: "AcademySports",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VideoSubmissions_Athletes_AthleteId",
                        column: x => x.AthleteId,
                        principalTable: "Athletes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VideoComments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VideoSubmissionId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuthorUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Message = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    VoiceNoteS3Key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VideoComments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VideoComments_Users_AuthorUserId",
                        column: x => x.AuthorUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VideoComments_VideoSubmissions_VideoSubmissionId",
                        column: x => x.VideoSubmissionId,
                        principalTable: "VideoSubmissions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VideoViews",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VideoSubmissionId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ViewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VideoViews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VideoViews_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VideoViews_VideoSubmissions_VideoSubmissionId",
                        column: x => x.VideoSubmissionId,
                        principalTable: "VideoSubmissions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_VideoComments_AuthorUserId",
                table: "VideoComments",
                column: "AuthorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_VideoComments_VideoSubmissionId",
                table: "VideoComments",
                column: "VideoSubmissionId");

            migrationBuilder.CreateIndex(
                name: "IX_VideoSubmissions_AthleteId",
                table: "VideoSubmissions",
                column: "AthleteId");

            migrationBuilder.CreateIndex(
                name: "IX_VideoSubmissions_SportId",
                table: "VideoSubmissions",
                column: "SportId");

            migrationBuilder.CreateIndex(
                name: "IX_VideoSubmissions_Status",
                table: "VideoSubmissions",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_VideoViews_UserId",
                table: "VideoViews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_VideoViews_VideoSubmissionId",
                table: "VideoViews",
                column: "VideoSubmissionId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "VideoComments");

            migrationBuilder.DropTable(
                name: "VideoViews");

            migrationBuilder.DropTable(
                name: "VideoSubmissions");
        }
    }
}
