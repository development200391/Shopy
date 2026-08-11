namespace shopy_api.Services;

public interface IFileStorage
{
    /// <summary>Simpan file, return path relatif (mis. "/uploads/logo/&lt;guid&gt;.png") — bukan
    /// URL absolut, karena server tidak tahu base URL mana yang dipakai client (device beda-beda).</summary>
    Task<string> SaveAsync(IFormFile file, string category);
}
