using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models.Catalog;
using shopy_api.Models.Notifications;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/notifications")]
public class NotificationsController(ShopyDbContext dbContext, INotificationService notificationService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<NotificationDto>>> GetNotifications(int page = 1, int pageSize = 20)
    {
        var userId = User.GetUserId();
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Notifications.Where(n => n.UserId == userId).OrderByDescending(n => n.CreatedAt);
        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new NotificationDto(n.Id, n.Type.ToString(), n.Title, n.Body, n.OrderId, n.IsRead, n.CreatedAt))
            .ToListAsync();

        return Ok(new PagedResult<NotificationDto>(items, page, pageSize, totalCount));
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<int>> GetUnreadCount()
    {
        var userId = User.GetUserId();
        var count = await dbContext.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead);
        return Ok(count);
    }

    [HttpPatch("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id)
    {
        var userId = User.GetUserId();
        var notification = await dbContext.Notifications.SingleOrDefaultAsync(n => n.Id == id && n.UserId == userId);
        if (notification is null)
        {
            return NotFound(new { message = "Notifikasi tidak ditemukan." });
        }

        notification.IsRead = true;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        var userId = User.GetUserId();
        await dbContext.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(setters => setters.SetProperty(n => n.IsRead, true));
        return NoContent();
    }

    /// <summary>
    /// Broadcast notifikasi promo ke semua user. Sama seperti endpoint update status
    /// pesanan di Fase 4 — app ini belum punya role admin/seller terpisah, jadi
    /// endpoint ini masih terbuka buat user manapun yang login (lihat TASKS.md Fase 6).
    /// </summary>
    [HttpPost("promo")]
    public async Task<IActionResult> BroadcastPromo(BroadcastPromoRequest request)
    {
        var count = await notificationService.BroadcastPromoAsync(request.Title, request.Body);
        return Ok(new { recipientCount = count });
    }
}
