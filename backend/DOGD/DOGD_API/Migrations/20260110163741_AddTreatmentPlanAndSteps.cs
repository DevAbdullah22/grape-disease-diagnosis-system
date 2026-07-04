using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class AddTreatmentPlanAndSteps : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "TreatmentPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DiseaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TreatmentPlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TreatmentPlans_Diseases_DiseaseId",
                        column: x => x.DiseaseId,
                        principalTable: "Diseases",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TreatmentSteps",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TreatmentPlanId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    StepOrder = table.Column<int>(type: "int", nullable: false),
                    PesticideName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ChemicalGroup = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PesticideImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DosageInstructions = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    MixQuantityAndType = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SafetyInfo = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ImportantNotes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IntervalDays = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TreatmentSteps", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TreatmentSteps_TreatmentPlans_TreatmentPlanId",
                        column: x => x.TreatmentPlanId,
                        principalTable: "TreatmentPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentPlans_DiseaseId",
                table: "TreatmentPlans",
                column: "DiseaseId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentSteps_TreatmentPlanId_StepOrder",
                table: "TreatmentSteps",
                columns: new[] { "TreatmentPlanId", "StepOrder" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TreatmentSteps");

            migrationBuilder.DropTable(
                name: "TreatmentPlans");
        }
    }
}
