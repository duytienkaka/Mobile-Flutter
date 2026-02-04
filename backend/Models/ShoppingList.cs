using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class ShoppingList
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

    [Required, MaxLength(120)]
    public string Name { get; set; } = "";

    public DateTime PlanDate { get; set; } = DateTime.UtcNow.Date;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsCompleted { get; set; } = false;

    // Navigation
    public ICollection<ShoppingItem> Items { get; set; } = new List<ShoppingItem>();
}
