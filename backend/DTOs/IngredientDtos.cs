namespace Backend.DTOs;

public class IngredientResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public DateTime? ExpiredAt { get; set; }
}
