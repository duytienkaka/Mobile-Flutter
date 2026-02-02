using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class RecipeQuery
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    // JSON snapshot nguyên liệu gửi AI
    [Required]
    public string IngredientsSnapshot { get; set; } = "";

    [MaxLength(50)]
    public string AiProvider { get; set; } = "GPT";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
