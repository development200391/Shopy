using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models.Catalog;

namespace shopy_api.Controllers;

[ApiController]
[Route("api/categories")]
public class CategoriesController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> GetRootCategories()
    {
        var categories = await dbContext.Categories
            .Where(c => c.ParentCategoryId == null)
            .OrderBy(c => c.Name)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Slug, c.ImageUrl, c.ParentCategoryId))
            .ToListAsync();

        return Ok(categories);
    }

    [HttpGet("{slug}")]
    public async Task<ActionResult<CategoryDetailDto>> GetBySlug(string slug)
    {
        var category = await dbContext.Categories
            .Include(c => c.ChildCategories)
            .SingleOrDefaultAsync(c => c.Slug == slug);

        if (category is null)
        {
            return NotFound(new { message = "Kategori tidak ditemukan." });
        }

        var dto = new CategoryDetailDto(
            category.Id,
            category.Name,
            category.Slug,
            category.ImageUrl,
            category.ParentCategoryId,
            category.ChildCategories
                .OrderBy(c => c.Name)
                .Select(c => new CategoryDto(c.Id, c.Name, c.Slug, c.ImageUrl, c.ParentCategoryId))
                .ToList());

        return Ok(dto);
    }
}
