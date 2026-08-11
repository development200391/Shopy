namespace shopy_api.Services;

public class LocalFileStorage(IWebHostEnvironment env) : IFileStorage
{
    public async Task<string> SaveAsync(IFormFile file, string category)
    {
        var webRootPath = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        var uploadsDir = Path.Combine(webRootPath, "uploads", category);
        Directory.CreateDirectory(uploadsDir);

        var extension = Path.GetExtension(file.FileName);
        var fileName = $"{Guid.NewGuid()}{extension}";
        var fullPath = Path.Combine(uploadsDir, fileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return $"/uploads/{category}/{fileName}";
    }
}
