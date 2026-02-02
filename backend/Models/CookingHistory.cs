using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class CookingHistory
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [Required, MaxLength(150)]
    public string RecipeName { get; set; } = "";

    [MaxLength(50)]
    public string RecipeSource { get; set; } = "AI";

    public DateTime CookedAt { get; set; } = DateTime.UtcNow;
}
