namespace Backend.DTOs;

public class RecipeIngredientDto
{
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
}

public class RecipeSuggestionDto
{
    public string Name { get; set; } = "";
    public int TimeMinutes { get; set; }
    public string ImageUrl { get; set; } = "";
    public List<RecipeIngredientDto> Ingredients { get; set; } = new();
    public List<RecipeIngredientDto> MissingIngredients { get; set; } = new();
}

public class RecipeSuggestionsResponse
{
    public DateTime GeneratedAt { get; set; }
    public List<RecipeSuggestionDto> FullRecipes { get; set; } = new();
    public List<RecipeSuggestionDto> NearRecipes { get; set; } = new();
}

public class RecipeCookRequest
{
    public string RecipeName { get; set; } = "";
    public string? RecipeSource { get; set; }
}

public class RecipeInstructionsRequest
{
    public string RecipeName { get; set; } = "";
    public List<string> Ingredients { get; set; } = new();
    public int StepCount { get; set; } = 4;
}

public class RecipeInstructionsResponse
{
    public List<string> SummarySteps { get; set; } = new();
    public List<string> DetailedSteps { get; set; } = new();
}
