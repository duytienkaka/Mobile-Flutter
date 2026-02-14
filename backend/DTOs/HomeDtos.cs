namespace Backend.DTOs;

public class HomeTipDto
{
    public string Category { get; set; } = "";
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
}

public class HomeAiResponse
{
    public DateTime GeneratedAt { get; set; }
    public List<RecipeSuggestionDto> RecommendedRecipes { get; set; } = new();
    public List<HomeTipDto> StorageTips { get; set; } = new();
}
