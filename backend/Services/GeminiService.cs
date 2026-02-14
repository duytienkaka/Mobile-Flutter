using System.Text;
using System.Text.Json;

namespace Backend.Services;

public class GeminiService
{
    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);

    public GeminiService(HttpClient http, IConfiguration config)
    {
        _http = http;
        _config = config;
    }

    public async Task<List<GeminiRecipe>> GenerateRecipesAsync(
        List<GeminiIngredient> pantryIngredients,
        List<string> recentRecipes,
        int count,
        string mode,
        CancellationToken ct)
    {
        var prompt = BuildPrompt(pantryIngredients, recentRecipes, count, mode);
        return await ExecutePromptAsync(prompt, ct);
    }

    public async Task<List<GeminiStorageTip>> GenerateStorageTipsAsync(
        Dictionary<string, List<string>> categorizedIngredients,
        CancellationToken ct)
    {
        var prompt = BuildStorageTipsPrompt(categorizedIngredients);
        return await ExecuteStorageTipsPromptAsync(prompt, ct);
    }

    public async Task<List<string>> GenerateInstructionsAsync(
        string recipeName,
        List<string> ingredients,
        int stepCount,
        CancellationToken ct)
    {
        var prompt = BuildInstructionsPrompt(recipeName, ingredients, stepCount);
        var result = await ExecuteInstructionsPromptAsync(prompt, ct);
        return result.DetailedSteps.Count > 0 ? result.DetailedSteps : result.SummarySteps;
    }

    public async Task<GeminiInstructionDetailPayload> GenerateInstructionDetailsAsync(
        string recipeName,
        List<string> ingredients,
        int stepCount,
        CancellationToken ct)
    {
        var prompt = BuildInstructionsPrompt(recipeName, ingredients, stepCount);
        return await ExecuteInstructionsPromptAsync(prompt, ct);
    }

    private async Task<List<GeminiRecipe>> ExecutePromptAsync(
        string prompt,
        CancellationToken ct)
    {
        var apiKey = _config["Gemini:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Gemini API key is missing.");
        }

        var baseUrl = _config["Gemini:BaseUrl"]
            ?? "https://generativelanguage.googleapis.com/v1";

        var model = _config["Gemini:Model"]
            ?? "gemini-1.5-flash-001";


        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[] { new { text = prompt } }
                }
            },
            generationConfig = new
            {
                temperature = 0.7
            }
        };

        var url = $"{baseUrl}/models/{model}:generateContent?key={apiKey}";
        var requestJson = JsonSerializer.Serialize(requestBody, _jsonOptions);
        using var response = await _http.PostAsync(
            url,
            new StringContent(requestJson, Encoding.UTF8, "application/json"),
            ct
        );

        var responseText = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Gemini request failed: {(int)response.StatusCode} {responseText}"
            );
        }

        var text = ExtractTextFromResponse(responseText);
        if (string.IsNullOrWhiteSpace(text))
        {
            return new List<GeminiRecipe>();
        }

        var jsonText = ExtractJson(text);
        if (jsonText == null)
        {
            return new List<GeminiRecipe>();
        }

        try
        {
            var payload = JsonSerializer.Deserialize<GeminiRecipePayload>(
                jsonText,
                _jsonOptions
            );
            return payload?.Recipes ?? new List<GeminiRecipe>();
        }
        catch
        {
            return new List<GeminiRecipe>();
        }
    }

    private async Task<List<GeminiStorageTip>> ExecuteStorageTipsPromptAsync(
        string prompt,
        CancellationToken ct)
    {
        var apiKey = _config["Gemini:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Gemini API key is missing.");
        }

        var baseUrl = _config["Gemini:BaseUrl"]
            ?? "https://generativelanguage.googleapis.com/v1";

        var model = _config["Gemini:Model"]
            ?? "gemini-1.5-flash-001";

        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[] { new { text = prompt } }
                }
            },
            generationConfig = new
            {
                temperature = 0.6
            }
        };

        var url = $"{baseUrl}/models/{model}:generateContent?key={apiKey}";
        var requestJson = JsonSerializer.Serialize(requestBody, _jsonOptions);
        using var response = await _http.PostAsync(
            url,
            new StringContent(requestJson, Encoding.UTF8, "application/json"),
            ct
        );

        var responseText = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Gemini request failed: {(int)response.StatusCode} {responseText}"
            );
        }

        var text = ExtractTextFromResponse(responseText);
        if (string.IsNullOrWhiteSpace(text))
        {
            return new List<GeminiStorageTip>();
        }

        var jsonText = ExtractJson(text);
        if (jsonText == null)
        {
            return new List<GeminiStorageTip>();
        }

        try
        {
            var payload = JsonSerializer.Deserialize<GeminiStorageTipPayload>(
                jsonText,
                _jsonOptions
            );
            return payload?.Tips ?? new List<GeminiStorageTip>();
        }
        catch
        {
            return new List<GeminiStorageTip>();
        }
    }

    private async Task<GeminiInstructionDetailPayload> ExecuteInstructionsPromptAsync(
        string prompt,
        CancellationToken ct)
    {
        var apiKey = _config["Gemini:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Gemini API key is missing.");
        }

        var baseUrl = _config["Gemini:BaseUrl"]
            ?? "https://generativelanguage.googleapis.com/v1";

        var model = _config["Gemini:Model"]
            ?? "gemini-1.5-flash-001";

        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[] { new { text = prompt } }
                }
            },
            generationConfig = new
            {
                temperature = 0.6
            }
        };

        var url = $"{baseUrl}/models/{model}:generateContent?key={apiKey}";
        var requestJson = JsonSerializer.Serialize(requestBody, _jsonOptions);
        using var response = await _http.PostAsync(
            url,
            new StringContent(requestJson, Encoding.UTF8, "application/json"),
            ct
        );

        var responseText = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Gemini request failed: {(int)response.StatusCode} {responseText}"
            );
        }

        var text = ExtractTextFromResponse(responseText);
        if (string.IsNullOrWhiteSpace(text))
        {
            return new GeminiInstructionDetailPayload();
        }

        var jsonText = ExtractJson(text);
        if (jsonText == null)
        {
            return new GeminiInstructionDetailPayload();
        }

        try
        {
            var payload = JsonSerializer.Deserialize<GeminiInstructionDetailPayload>(
                jsonText,
                _jsonOptions
            );
            return payload ?? new GeminiInstructionDetailPayload();
        }
        catch
        {
            return new GeminiInstructionDetailPayload();
        }
    }

    private static string BuildPrompt(
        List<GeminiIngredient> pantryIngredients,
        List<string> recentRecipes,
        int count,
        string mode)
    {
        var ingredientsJson = JsonSerializer.Serialize(pantryIngredients);
        var pantryKeywords = pantryIngredients
            .Select(x => x.Name?.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        var pantryKeywordsJson = JsonSerializer.Serialize(pantryKeywords);
        var recentJson = JsonSerializer.Serialize(recentRecipes);
        var modeText = mode.Trim().ToLowerInvariant();

        var constraint = modeText switch
        {
            "full" => "Every ingredient name must be exactly one pantry keyword. Do not include any ingredient outside the pantry keywords.",
            "near" => "Use pantry keywords exactly for available ingredients. Missing ingredients are allowed but must be at most one third of the list.",
            _ => "Use pantry keywords exactly. If missing ingredients are needed, keep them minimal."
        };

        return $$"""
You are a helpful cooking assistant for a Vietnamese food app.
Return ONLY valid JSON in this exact schema:
{
    "recipes": [
        {
            "name": "",
            "timeMinutes": 0,
            "imageUrl": "",
            "ingredients": [
                { "name": "", "quantity": 1, "unit": "" }
            ]
        }
    ]
}

Rules:
- Generate {{count}} distinct recipe items.
- Avoid any recipe names present in this list: {{recentJson}}
- Use common Vietnamese dishes where possible.
- {{constraint}}
- When you use a pantry ingredient, the name must exactly match a pantry keyword (no synonyms, no partial names).
- timeMinutes must be an integer (15-90).
- imageUrl must be a public https image URL (Unsplash or Pexels) that matches the dish.
- ingredients must be a realistic list of needed ingredients for the dish.
- If quantity or unit is unknown, use quantity 1 and unit "".

Available pantry ingredients (may be partial): {{ingredientsJson}}
Pantry keywords (exact names only): {{pantryKeywordsJson}}
""";
    }

    private static string BuildStorageTipsPrompt(
        Dictionary<string, List<string>> categorizedIngredients)
    {
        var categoriesJson = JsonSerializer.Serialize(categorizedIngredients);
        var categories = categorizedIngredients.Keys.ToList();
        var categoryList = string.Join(", ", categories);

        return $$"""
You are a helpful cooking assistant for a Vietnamese food app.
Return ONLY valid JSON in this exact schema:
{
    "tips": [
        {
            "category": "fruit|vegetable|meat",
            "title": "",
            "message": ""
        }
    ]
}

Rules:
- Generate exactly one tip per category present: {{categoryList}}
- Category must be one of: fruit, vegetable, meat
- Write in Vietnamese.
- Keep each message concise (1-2 sentences).

Ingredients by category: {{categoriesJson}}
""";
    }

    private static string BuildInstructionsPrompt(
        string recipeName,
        List<string> ingredients,
        int stepCount)
    {
        var ingredientsJson = JsonSerializer.Serialize(ingredients);
        var safeName = recipeName.Trim();
        var steps = stepCount <= 0 ? 4 : stepCount;

        return $$"""
You are a helpful cooking assistant for a Vietnamese food app.
Return ONLY valid JSON in this exact schema:
{
    "summarySteps": [""],
    "detailedSteps": [""]
}

Rules:
- Write instructions in Vietnamese.
- Generate exactly {{steps}} steps.
- summarySteps: 1 sentence per step.
- detailedSteps: 3-4 sentences per step with concrete actions, timings, and quantities when possible.
- Include prep, cooking, and finishing details when relevant.
- Use the given ingredients where relevant.

Recipe name: {{safeName}}
Ingredients: {{ingredientsJson}}
""";
    }

    private static string? ExtractTextFromResponse(string responseText)
    {
        try
        {
            using var doc = JsonDocument.Parse(responseText);
            var root = doc.RootElement;
            if (!root.TryGetProperty("candidates", out var candidates))
            {
                return null;
            }

            foreach (var candidate in candidates.EnumerateArray())
            {
                if (!candidate.TryGetProperty("content", out var content))
                {
                    continue;
                }

                if (!content.TryGetProperty("parts", out var parts))
                {
                    continue;
                }

                foreach (var part in parts.EnumerateArray())
                {
                    if (part.TryGetProperty("text", out var text))
                    {
                        return text.GetString();
                    }
                }
            }
        }
        catch
        {
            return null;
        }

        return null;
    }

    private static string? ExtractJson(string text)
    {
        var start = text.IndexOf('{');
        var end = text.LastIndexOf('}');
        if (start < 0 || end <= start)
        {
            return null;
        }

        return text.Substring(start, end - start + 1);
    }
}

public class GeminiRecipePayload
{
    public List<GeminiRecipe> Recipes { get; set; } = new();
}

public class GeminiRecipe
{
    public string Name { get; set; } = "";
    public int TimeMinutes { get; set; }
    public string ImageUrl { get; set; } = "";
    public List<GeminiIngredient> Ingredients { get; set; } = new();
}

public class GeminiIngredient
{
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
}

public class GeminiStorageTipPayload
{
    public List<GeminiStorageTip> Tips { get; set; } = new();
}

public class GeminiStorageTip
{
    public string Category { get; set; } = "";
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
}

public class GeminiInstructionDetailPayload
{
    public List<string> SummarySteps { get; set; } = new();
    public List<string> DetailedSteps { get; set; } = new();
}
