using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs;

public class MealPlanCreateRequest
{
    [Required]
    public DateTime Date { get; set; }

    [Required, MaxLength(20)]
    public string MealType { get; set; } = "";

    [Required, MaxLength(150)]
    public string RecipeName { get; set; } = "";

    public int Servings { get; set; } = 1;

    [MaxLength(200)]
    public string? Note { get; set; }
}

public class MealPlanUpdateRequest
{
    [Required]
    public DateTime Date { get; set; }

    [Required, MaxLength(20)]
    public string MealType { get; set; } = "";

    [Required, MaxLength(150)]
    public string RecipeName { get; set; } = "";

    public int Servings { get; set; } = 1;

    [MaxLength(200)]
    public string? Note { get; set; }
}

public class MealPlanResponse
{
    public Guid Id { get; set; }
    public DateTime Date { get; set; }
    public string MealType { get; set; } = "";
    public string RecipeName { get; set; } = "";
    public int Servings { get; set; }
    public string? Note { get; set; }
}
