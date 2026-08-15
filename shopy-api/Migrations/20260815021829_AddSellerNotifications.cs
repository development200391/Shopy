using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace shopy_api.Migrations
{
    /// <inheritdoc />
    public partial class AddSellerNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "StoreId",
                table: "Notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AppType",
                table: "DeviceTokens",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "Buyer");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_StoreId",
                table: "Notifications",
                column: "StoreId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Stores_StoreId",
                table: "Notifications",
                column: "StoreId",
                principalTable: "Stores",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Stores_StoreId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_StoreId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "StoreId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "AppType",
                table: "DeviceTokens");
        }
    }
}
