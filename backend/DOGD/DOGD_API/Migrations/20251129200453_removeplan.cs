using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class removeplan : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TreatmentPlans");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "TreatmentPlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DiseaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DosageInstructions = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DoseIntervalDays = table.Column<int>(type: "int", nullable: false),
                    PesticideImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PesticideName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SafetyInfo = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TotalDoses = table.Column<int>(type: "int", nullable: false)
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

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentPlans_DiseaseId",
                table: "TreatmentPlans",
                column: "DiseaseId",
                unique: true);
        }
    }
}
