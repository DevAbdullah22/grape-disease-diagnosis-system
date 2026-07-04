using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class PlanDoseInterval : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IntervalDays",
                table: "TreatmentSteps");

            migrationBuilder.AddColumn<int>(
                name: "DoseIntervalDays",
                table: "TreatmentPlans",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DoseIntervalDays",
                table: "TreatmentPlans");

            migrationBuilder.AddColumn<int>(
                name: "IntervalDays",
                table: "TreatmentSteps",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
