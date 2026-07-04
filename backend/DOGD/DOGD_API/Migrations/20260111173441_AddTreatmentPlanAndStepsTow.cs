using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class AddTreatmentPlanAndStepsTow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TreatmentRules");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "TreatmentRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DiseaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DosageInstructions = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DoseIntervalDays = table.Column<int>(type: "int", nullable: false),
                    ImportantNotes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MaxSeverity = table.Column<double>(type: "float", nullable: false),
                    MinSeverity = table.Column<double>(type: "float", nullable: false),
                    MixQuantityAndType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PesticideImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PesticideName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SafetyInfo = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TotalDoses = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TreatmentRules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TreatmentRules_Diseases_DiseaseId",
                        column: x => x.DiseaseId,
                        principalTable: "Diseases",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentRules_DiseaseId",
                table: "TreatmentRules",
                column: "DiseaseId",
                unique: true);
        }
    }
}
