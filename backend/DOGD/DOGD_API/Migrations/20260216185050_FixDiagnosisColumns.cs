using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class FixDiagnosisColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<float>(
         name: "DamagePercentage",
         table: "Diagnoses",
         type: "real",
         nullable: false,
         defaultValue: 0f);

            migrationBuilder.DropColumn(
                name: "Stage",
                table: "Diagnoses");

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
       name: "Stage",
       table: "Diagnoses",
       type: "nvarchar(max)",
       nullable: true);

            migrationBuilder.DropColumn(
                name: "DamagePercentage",
                table: "Diagnoses");

        }
    }
}
