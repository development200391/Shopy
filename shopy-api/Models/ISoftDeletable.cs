namespace shopy_api.Models;

public interface ISoftDeletable
{
    bool IsDeleted { get; set; }
}
