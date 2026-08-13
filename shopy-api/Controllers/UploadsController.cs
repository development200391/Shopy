using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/uploads")]
public class UploadsController(IFileStorage fileStorage) : ControllerBase
{
    private const long MaxFileSizeBytes = 5 * 1024 * 1024;

    private static readonly Dictionary<string, string[]> AllowedContentTypesByCategory = new()
    {
        ["logo"] = ["image/jpeg", "image/png", "image/webp"],
        ["banner"] = ["image/jpeg", "image/png", "image/webp"],
        ["product"] = ["image/jpeg", "image/png", "image/webp"],
        ["document"] = ["image/jpeg", "image/png", "application/pdf"],
    };

    [HttpPost]
    [RequestSizeLimit(MaxFileSizeBytes)]
    public async Task<IActionResult> Upload([FromQuery] string category, IFormFile? file)
    {
        if (!AllowedContentTypesByCategory.TryGetValue(category, out var allowedContentTypes))
        {
            return BadRequest(new { message = "Kategori upload tidak dikenal." });
        }

        if (file is null || file.Length == 0)
        {
            return BadRequest(new { message = "File wajib diisi." });
        }

        if (file.Length > MaxFileSizeBytes)
        {
            return BadRequest(new { message = "Ukuran file maksimal 5MB." });
        }

        if (!allowedContentTypes.Contains(file.ContentType))
        {
            return BadRequest(new { message = $"Tipe file tidak didukung untuk kategori {category}." });
        }

        var url = await fileStorage.SaveAsync(file, category);
        return Ok(new { url });
    }
}
