using Microsoft.EntityFrameworkCore;

namespace shopy_api.Data;

public class ShopyDbContext(DbContextOptions<ShopyDbContext> options) : DbContext(options)
{
}
