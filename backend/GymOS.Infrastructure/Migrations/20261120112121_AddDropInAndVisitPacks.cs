using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GymOS.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDropInAndVisitPacks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RemainingVisits",
                table: "Subscriptions",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Kind",
                table: "Plans",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "VisitsIncluded",
                table: "Plans",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDropIn",
                table: "PaymentRecords",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "OperationId",
                table: "PaymentRecords",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReversedPaymentId",
                table: "PaymentRecords",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsGuest",
                table: "AspNetUsers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_PaymentRecords_TenantId_OperationId",
                table: "PaymentRecords",
                columns: new[] { "TenantId", "OperationId" },
                unique: true,
                filter: "\"OperationId\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PaymentRecords_TenantId_OperationId",
                table: "PaymentRecords");

            migrationBuilder.DropColumn(
                name: "RemainingVisits",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "Kind",
                table: "Plans");

            migrationBuilder.DropColumn(
                name: "VisitsIncluded",
                table: "Plans");

            migrationBuilder.DropColumn(
                name: "IsDropIn",
                table: "PaymentRecords");

            migrationBuilder.DropColumn(
                name: "OperationId",
                table: "PaymentRecords");

            migrationBuilder.DropColumn(
                name: "ReversedPaymentId",
                table: "PaymentRecords");

            migrationBuilder.DropColumn(
                name: "IsGuest",
                table: "AspNetUsers");
        }
    }
}
