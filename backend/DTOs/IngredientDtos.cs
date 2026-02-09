namespace Backend.DTOs;

public class IngredientResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public DateTime? ExpiredAt { get; set; }
}

public class IngredientCreateRequest
{
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public DateTime? ExpiredAt { get; set; }
}

public class IngredientUpdateRequest
{
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public DateTime? ExpiredAt { get; set; }
}
