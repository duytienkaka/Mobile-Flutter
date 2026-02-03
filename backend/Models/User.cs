using System.ComponentModel.DataAnnotations;

namespace Backend.Models;

public class User
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, MaxLength(100)]
    public string FullName { get; set; } = "";

    [MaxLength(100)]
    public string? Email { get; set; }

    [MaxLength(20)]
    public string? PhoneNumber { get; set; }

    // Chỉ dùng cho email user
    public string? PasswordHash { get; set; }

    public bool IsEmailVerified { get; set; } = false;
    public bool IsPhoneVerified { get; set; } = false;

    [MaxLength(400)]
    public string? AvatarUrl { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Ingredient> Ingredients { get; set; } = new List<Ingredient>();
    public ICollection<ShoppingList> ShoppingLists { get; set; } = new List<ShoppingList>();
    public ICollection<CookingHistory> CookingHistories { get; set; } = new List<CookingHistory>();
    public ICollection<MealPlan> MealPlans { get; set; } = new List<MealPlan>();
}
