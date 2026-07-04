using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DOGD_API.Migrations
{
    /// <inheritdoc />
    public partial class CascadeDeleteLibrary : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_LibraryItems_LibraryCategories_CategoryId",
                table: "LibraryItems");

            migrationBuilder.AddForeignKey(
                name: "FK_LibraryItems_LibraryCategories_CategoryId",
                table: "LibraryItems",
                column: "CategoryId",
                principalTable: "LibraryCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_LibraryItems_LibraryCategories_CategoryId",
                table: "LibraryItems");

            migrationBuilder.AddForeignKey(
                name: "FK_LibraryItems_LibraryCategories_CategoryId",
                table: "LibraryItems",
                column: "CategoryId",
                principalTable: "LibraryCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
