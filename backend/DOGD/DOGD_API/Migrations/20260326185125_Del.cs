using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class Del : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SeasonalRules");

            migrationBuilder.DropTable(
                name: "UserNotificationTokens");

            migrationBuilder.DropColumn(
                name: "DamagePercentage",
                table: "Diagnoses");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<float>(
                name: "DamagePercentage",
                table: "Diagnoses",
                type: "real",
                nullable: false,
                defaultValue: 0f);

            migrationBuilder.CreateTable(
                name: "SeasonalRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DiseaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    MinOccurrences = table.Column<int>(type: "int", nullable: false),
                    MonthAppeared = table.Column<int>(type: "int", nullable: false),
                    ReminderMonth = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SeasonalRules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SeasonalRules_Diseases_DiseaseId",
                        column: x => x.DiseaseId,
                        principalTable: "Diseases",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "UserNotificationTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DeviceToken = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserNotificationTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserNotificationTokens_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SeasonalRules_DiseaseId",
                table: "SeasonalRules",
                column: "DiseaseId");

            migrationBuilder.CreateIndex(
                name: "IX_UserNotificationTokens_UserId",
                table: "UserNotificationTokens",
                column: "UserId");
        }
    }
}
