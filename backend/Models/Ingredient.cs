using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class Ingredient
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [Required, MaxLength(100)]
    public string Name { get; set; } = "";

    [MaxLength(30)]
    public string Category { get; set; } = "";

    public double Quantity { get; set; }

    [MaxLength(20)]
    public string Unit { get; set; } = "";

    public DateTime? ExpiredAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
