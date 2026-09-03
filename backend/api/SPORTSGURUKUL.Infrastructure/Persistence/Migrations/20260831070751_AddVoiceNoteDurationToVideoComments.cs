using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SPORTSGURUKUL.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddVoiceNoteDurationToVideoComments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "VoiceNoteDurationSeconds",
                table: "VideoComments",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "VoiceNoteDurationSeconds",
                table: "VideoComments");
        }
    }
}
