using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class RemoveUniqueIndexFromTreatmentRules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
        name: "IX_TreatmentRules_DiseaseId",
        table: "TreatmentRules"
    );

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentRules_DiseaseId",
                table: "TreatmentRules",
                column: "DiseaseId"
            );

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
        name: "IX_TreatmentRules_DiseaseId",
        table: "TreatmentRules"
    );

            migrationBuilder.CreateIndex(
                name: "IX_TreatmentRules_DiseaseId",
                table: "TreatmentRules",
                column: "DiseaseId",
                unique: true
            );
        }
    }
}
