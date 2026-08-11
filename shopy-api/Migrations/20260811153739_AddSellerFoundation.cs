using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace shopy_api.Migrations
{
    /// <inheritdoc />
    public partial class AddSellerFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImageUrls",
                table: "Reviews",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SellerRepliedAt",
                table: "Reviews",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SellerReply",
                table: "Reviews",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "StoreId",
                table: "Reviews",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SubOrderId",
                table: "Reviews",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Condition",
                table: "Products",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "DiscountEndAt",
                table: "Products",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DiscountPrice",
                table: "Products",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DiscountStartAt",
                table: "Products",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SoldCount",
                table: "Products",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "StoreId",
                table: "Products",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<int>(
                name: "ViewCount",
                table: "Products",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Weight",
                table: "Products",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "SubOrderId",
                table: "OrderItems",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ProductImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Url = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsPrimary = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProductImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProductImages_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Stores",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    LogoUrl = table.Column<string>(type: "text", nullable: true),
                    BannerUrl = table.Column<string>(type: "text", nullable: true),
                    PhoneNumber = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    IsOpen = table.Column<bool>(type: "boolean", nullable: false),
                    RatingAverage = table.Column<decimal>(type: "numeric(3,2)", precision: 3, scale: 2, nullable: false),
                    RatingCount = table.Column<int>(type: "integer", nullable: false),
                    ProductCount = table.Column<int>(type: "integer", nullable: false),
                    FollowerCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Stores", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Stores_AspNetUsers_OwnerUserId",
                        column: x => x.OwnerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "BankAccounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    BankCode = table.Column<string>(type: "text", nullable: false),
                    BankName = table.Column<string>(type: "text", nullable: false),
                    AccountNumber = table.Column<string>(type: "text", nullable: false),
                    AccountHolderName = table.Column<string>(type: "text", nullable: false),
                    IsVerified = table.Column<bool>(type: "boolean", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BankAccounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BankAccounts_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChatRooms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    BuyerUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    LastMessagePreview = table.Column<string>(type: "text", nullable: true),
                    UnreadCountSeller = table.Column<int>(type: "integer", nullable: false),
                    UnreadCountBuyer = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatRooms", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatRooms_AspNetUsers_BuyerUserId",
                        column: x => x.BuyerUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ChatRooms_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "FlashSales",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    StartAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FlashSales", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FlashSales_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StoreAddresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    Label = table.Column<string>(type: "text", nullable: false),
                    PicName = table.Column<string>(type: "text", nullable: false),
                    PhoneNumber = table.Column<string>(type: "text", nullable: false),
                    FullAddress = table.Column<string>(type: "text", nullable: false),
                    City = table.Column<string>(type: "text", nullable: false),
                    Province = table.Column<string>(type: "text", nullable: false),
                    PostalCode = table.Column<string>(type: "text", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StoreAddresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StoreAddresses_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StoreBalances",
                columns: table => new
                {
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    AvailableBalance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    PendingBalance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalEarning = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StoreBalances", x => x.StoreId);
                    table.ForeignKey(
                        name: "FK_StoreBalances_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StoreDocuments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    FileUrl = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RejectReason = table.Column<string>(type: "text", nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StoreDocuments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StoreDocuments_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StoreFollowers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StoreFollowers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StoreFollowers_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_StoreFollowers_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SubOrders",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    SubOrderNumber = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Subtotal = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    ShippingCost = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    VoucherDiscount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CommissionAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    SellerEarning = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CourierCode = table.Column<string>(type: "text", nullable: true),
                    CourierService = table.Column<string>(type: "text", nullable: true),
                    TrackingNumber = table.Column<string>(type: "text", nullable: true),
                    ShippedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AutoCancelAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CancelReason = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubOrders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SubOrders_Orders_OrderId",
                        column: x => x.OrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubOrders_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Vouchers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Value = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    MaxDiscount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    MinPurchase = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    Quota = table.Column<int>(type: "integer", nullable: true),
                    UsedCount = table.Column<int>(type: "integer", nullable: false),
                    StartAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Vouchers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Vouchers_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Withdrawals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    BankAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    AdminFee = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    NetAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RejectReason = table.Column<string>(type: "text", nullable: true),
                    RequestedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    ProcessedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Withdrawals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Withdrawals_BankAccounts_BankAccountId",
                        column: x => x.BankAccountId,
                        principalTable: "BankAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Withdrawals_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "FlashSaleItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FlashSaleId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    SpecialPrice = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Quota = table.Column<int>(type: "integer", nullable: false),
                    SoldCount = table.Column<int>(type: "integer", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FlashSaleItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FlashSaleItems_FlashSales_FlashSaleId",
                        column: x => x.FlashSaleId,
                        principalTable: "FlashSales",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FlashSaleItems_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ChatMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ChatRoomId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    SenderUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Body = table.Column<string>(type: "text", nullable: true),
                    AttachmentUrl = table.Column<string>(type: "text", nullable: true),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: true),
                    SubOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatMessages_ChatRooms_ChatRoomId",
                        column: x => x.ChatRoomId,
                        principalTable: "ChatRooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChatMessages_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ChatMessages_SubOrders_SubOrderId",
                        column: x => x.SubOrderId,
                        principalTable: "SubOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SubOrderStatusHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SubOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Note = table.Column<string>(type: "text", nullable: true),
                    ChangedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ChangedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubOrderStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SubOrderStatusHistories_SubOrders_SubOrderId",
                        column: x => x.SubOrderId,
                        principalTable: "SubOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VoucherUsages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VoucherId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SubOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    DiscountAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    UsedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VoucherUsages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VoucherUsages_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VoucherUsages_SubOrders_SubOrderId",
                        column: x => x.SubOrderId,
                        principalTable: "SubOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_VoucherUsages_Vouchers_VoucherId",
                        column: x => x.VoucherId,
                        principalTable: "Vouchers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "BalanceTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StoreId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    BalanceAfter = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    SubOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    WithdrawalId = table.Column<Guid>(type: "uuid", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BalanceTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BalanceTransactions_Stores_StoreId",
                        column: x => x.StoreId,
                        principalTable: "Stores",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BalanceTransactions_SubOrders_SubOrderId",
                        column: x => x.SubOrderId,
                        principalTable: "SubOrders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BalanceTransactions_Withdrawals_WithdrawalId",
                        column: x => x.WithdrawalId,
                        principalTable: "Withdrawals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_StoreId",
                table: "Reviews",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_SubOrderId",
                table: "Reviews",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Products_StoreId",
                table: "Products",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_SubOrderId",
                table: "OrderItems",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_BalanceTransactions_StoreId",
                table: "BalanceTransactions",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_BalanceTransactions_SubOrderId",
                table: "BalanceTransactions",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_BalanceTransactions_WithdrawalId",
                table: "BalanceTransactions",
                column: "WithdrawalId");

            migrationBuilder.CreateIndex(
                name: "IX_BankAccounts_StoreId",
                table: "BankAccounts",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ChatRoomId",
                table: "ChatMessages",
                column: "ChatRoomId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ProductId",
                table: "ChatMessages",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_SubOrderId",
                table: "ChatMessages",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatRooms_BuyerUserId",
                table: "ChatRooms",
                column: "BuyerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatRooms_StoreId_BuyerUserId",
                table: "ChatRooms",
                columns: new[] { "StoreId", "BuyerUserId" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_FlashSaleItems_FlashSaleId",
                table: "FlashSaleItems",
                column: "FlashSaleId");

            migrationBuilder.CreateIndex(
                name: "IX_FlashSaleItems_ProductId",
                table: "FlashSaleItems",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_FlashSales_StoreId",
                table: "FlashSales",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_ProductImages_ProductId",
                table: "ProductImages",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_StoreAddresses_StoreId",
                table: "StoreAddresses",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_StoreDocuments_StoreId",
                table: "StoreDocuments",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_StoreFollowers_StoreId_UserId",
                table: "StoreFollowers",
                columns: new[] { "StoreId", "UserId" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_StoreFollowers_UserId",
                table: "StoreFollowers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Stores_OwnerUserId",
                table: "Stores",
                column: "OwnerUserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Stores_Slug",
                table: "Stores",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SubOrders_OrderId",
                table: "SubOrders",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_SubOrders_StoreId",
                table: "SubOrders",
                column: "StoreId");

            migrationBuilder.CreateIndex(
                name: "IX_SubOrders_SubOrderNumber",
                table: "SubOrders",
                column: "SubOrderNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SubOrderStatusHistories_SubOrderId",
                table: "SubOrderStatusHistories",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_Vouchers_StoreId_Code",
                table: "Vouchers",
                columns: new[] { "StoreId", "Code" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_VoucherUsages_SubOrderId",
                table: "VoucherUsages",
                column: "SubOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_VoucherUsages_UserId",
                table: "VoucherUsages",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_VoucherUsages_VoucherId",
                table: "VoucherUsages",
                column: "VoucherId");

            migrationBuilder.CreateIndex(
                name: "IX_Withdrawals_BankAccountId",
                table: "Withdrawals",
                column: "BankAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_Withdrawals_StoreId",
                table: "Withdrawals",
                column: "StoreId");

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_SubOrders_SubOrderId",
                table: "OrderItems",
                column: "SubOrderId",
                principalTable: "SubOrders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            // Backfill: Products.StoreId di atas sengaja diberi default GUID kosong supaya kolom
            // NOT NULL bisa ditambahkan tanpa gagal walau tabel sudah berisi data. Sebelum FK
            // constraint-nya dipasang, ganti nilai default itu ke 1 "toko migrasi" fallback
            // (dibuat cuma kalau memang ada baris yang butuh) — CatalogSeeder dev sendiri sudah
            // mengisi StoreId yang benar sejak awal, jadi blok ini idempotent/no-op di DB kosong.
            migrationBuilder.Sql(
                """
                DO $$
                DECLARE
                    fallback_store_id uuid;
                    fallback_user_id uuid;
                BEGIN
                    IF EXISTS (SELECT 1 FROM "Products" WHERE "StoreId" = '00000000-0000-0000-0000-000000000000') THEN
                        fallback_user_id := gen_random_uuid();
                        INSERT INTO "AspNetUsers" (
                            "Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed",
                            "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled",
                            "LockoutEnabled", "AccessFailedCount", "FullName", "CreatedAt", "IsDeleted"
                        ) VALUES (
                            fallback_user_id, 'toko-migrasi@shopy.local', 'TOKO-MIGRASI@SHOPY.LOCAL',
                            'toko-migrasi@shopy.local', 'TOKO-MIGRASI@SHOPY.LOCAL', true,
                            gen_random_uuid()::text, gen_random_uuid()::text, false, false,
                            true, 0, 'Toko Migrasi', now(), false
                        );

                        fallback_store_id := gen_random_uuid();
                        INSERT INTO "Stores" (
                            "Id", "OwnerUserId", "Name", "Slug", "Status", "IsOpen",
                            "RatingAverage", "RatingCount", "ProductCount", "FollowerCount",
                            "CreatedAt", "UpdatedAt", "IsDeleted"
                        ) VALUES (
                            fallback_store_id, fallback_user_id, 'Toko Migrasi', 'toko-migrasi', 'Active', true,
                            0, 0, 0, 0, now(), now(), false
                        );

                        UPDATE "Products" SET "StoreId" = fallback_store_id
                        WHERE "StoreId" = '00000000-0000-0000-0000-000000000000';
                    END IF;
                END $$;
                """);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_Stores_StoreId",
                table: "Products",
                column: "StoreId",
                principalTable: "Stores",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Stores_StoreId",
                table: "Reviews",
                column: "StoreId",
                principalTable: "Stores",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_SubOrders_SubOrderId",
                table: "Reviews",
                column: "SubOrderId",
                principalTable: "SubOrders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            // Backfill: generate SubOrders untuk Orders lama (pra-Fase 0), dikelompokkan per toko
            // pemilik produknya (butuh Products.StoreId yang sudah dibackfill di atas). CommissionAmount
            // sengaja 0 / SellerEarning = Subtotal di sini — mesin hitung komisi asli baru ada Fase 5.
            migrationBuilder.Sql(
                """
                DO $$
                DECLARE
                    ord RECORD;
                    grp RECORD;
                    new_suborder_id uuid;
                    seq_no int;
                BEGIN
                    FOR ord IN
                        SELECT o."Id", o."OrderNumber", o."Status", o."ShippingCost", o."CreatedAt", o."UpdatedAt"
                        FROM "Orders" o
                        WHERE NOT EXISTS (SELECT 1 FROM "SubOrders" so WHERE so."OrderId" = o."Id")
                    LOOP
                        seq_no := 0;
                        FOR grp IN
                            SELECT p."StoreId" AS store_id, SUM(oi."Subtotal") AS subtotal
                            FROM "OrderItems" oi
                            JOIN "Products" p ON p."Id" = oi."ProductId"
                            WHERE oi."OrderId" = ord."Id"
                            GROUP BY p."StoreId"
                        LOOP
                            seq_no := seq_no + 1;
                            new_suborder_id := gen_random_uuid();
                            INSERT INTO "SubOrders" (
                                "Id", "OrderId", "StoreId", "SubOrderNumber", "Status",
                                "Subtotal", "ShippingCost", "VoucherDiscount", "CommissionAmount", "SellerEarning",
                                "CreatedAt", "UpdatedAt", "IsDeleted"
                            ) VALUES (
                                new_suborder_id, ord."Id", grp.store_id, ord."OrderNumber" || '-' || seq_no,
                                CASE ord."Status"
                                    WHEN 'Pending' THEN 'NewOrder'
                                    WHEN 'Processing' THEN 'Processing'
                                    WHEN 'Shipped' THEN 'Shipped'
                                    WHEN 'Completed' THEN 'Completed'
                                    WHEN 'Cancelled' THEN 'Cancelled'
                                    ELSE 'NewOrder'
                                END,
                                grp.subtotal,
                                CASE WHEN seq_no = 1 THEN ord."ShippingCost" ELSE 0 END,
                                0, 0, grp.subtotal,
                                ord."CreatedAt", ord."UpdatedAt", false
                            );

                            UPDATE "OrderItems" oi SET "SubOrderId" = new_suborder_id
                            FROM "Products" p
                            WHERE oi."ProductId" = p."Id" AND oi."OrderId" = ord."Id" AND p."StoreId" = grp.store_id;
                        END LOOP;
                    END LOOP;
                END $$;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_SubOrders_SubOrderId",
                table: "OrderItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Products_Stores_StoreId",
                table: "Products");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Stores_StoreId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_SubOrders_SubOrderId",
                table: "Reviews");

            migrationBuilder.DropTable(
                name: "BalanceTransactions");

            migrationBuilder.DropTable(
                name: "ChatMessages");

            migrationBuilder.DropTable(
                name: "FlashSaleItems");

            migrationBuilder.DropTable(
                name: "ProductImages");

            migrationBuilder.DropTable(
                name: "StoreAddresses");

            migrationBuilder.DropTable(
                name: "StoreBalances");

            migrationBuilder.DropTable(
                name: "StoreDocuments");

            migrationBuilder.DropTable(
                name: "StoreFollowers");

            migrationBuilder.DropTable(
                name: "SubOrderStatusHistories");

            migrationBuilder.DropTable(
                name: "VoucherUsages");

            migrationBuilder.DropTable(
                name: "Withdrawals");

            migrationBuilder.DropTable(
                name: "ChatRooms");

            migrationBuilder.DropTable(
                name: "FlashSales");

            migrationBuilder.DropTable(
                name: "SubOrders");

            migrationBuilder.DropTable(
                name: "Vouchers");

            migrationBuilder.DropTable(
                name: "BankAccounts");

            migrationBuilder.DropTable(
                name: "Stores");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_StoreId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_SubOrderId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Products_StoreId",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_OrderItems_SubOrderId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "ImageUrls",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "SellerRepliedAt",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "SellerReply",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "StoreId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "SubOrderId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "Condition",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "DiscountEndAt",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "DiscountPrice",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "DiscountStartAt",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "SoldCount",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "StoreId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "ViewCount",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "Weight",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "SubOrderId",
                table: "OrderItems");
        }
    }
}
