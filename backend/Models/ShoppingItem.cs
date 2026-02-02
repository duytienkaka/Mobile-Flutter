using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class ShoppingItem
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public Guid ShoppingListId { get; set; }

    [ForeignKey(nameof(ShoppingListId))]
    public ShoppingList ShoppingList { get; set; } = null!;

    [Required, MaxLength(100)]
    public string Name { get; set; } = "";

    public double Quantity { get; set; }

    [MaxLength(20)]
    public string Unit { get; set; } = "";

    public bool IsChecked { get; set; } = false;
}
