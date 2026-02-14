namespace Backend.DTOs.History;

public class CookingHistoryDto
{
	public Guid Id { get; set; }
	public string RecipeName { get; set; } = "";
	public string RecipeSource { get; set; } = "AI";
	public DateTime CookedAt { get; set; }
}
