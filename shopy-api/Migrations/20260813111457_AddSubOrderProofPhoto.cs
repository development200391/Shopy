using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace shopy_api.Migrations
{
    /// <inheritdoc />
    public partial class AddSubOrderProofPhoto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ProofPhotoUrl",
                table: "SubOrders",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProofPhotoUrl",
                table: "SubOrders");
        }
    }
}
