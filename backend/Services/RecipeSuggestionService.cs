using System.Globalization;
using System.Text;
using System.Text.Json;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class RecipeSuggestionService
{
    private readonly AppDbContext _db;
    private readonly GeminiService _gemini;

    private static readonly object _cacheLock = new();
    private static readonly Dictionary<string, CacheEntry> _cache = new();
    private static readonly Dictionary<string, TimedCacheEntry> _refreshCache = new();
    private const int RefreshCacheSeconds = 30;
    private const int PantryRecipeCount = 3;

    public RecipeSuggestionService(AppDbContext db, GeminiService gemini)
    {
        _db = db;
        _gemini = gemini;
    }

    public async Task<RecipeSuggestionsResponse> GetTodaySuggestions(
        Guid userId,
        bool refresh,
        string? tab,
        CancellationToken ct)
    {
        var normalizedTab = NormalizeTab(tab);
        var cacheKey = BuildCacheKey(userId, DateTime.UtcNow, normalizedTab);
        if (!refresh && TryGetCached(cacheKey, out var cached))
        {
            return FilterResponseByTab(cached, normalizedTab);
        }

        if (refresh && TryGetRefreshCached(cacheKey, out var refreshCached))
        {
            return FilterResponseByTab(refreshCached, normalizedTab);
        }

        var ingredients = await _db.Ingredients
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);

        var recentCooked = await _db.CookingHistories
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.CookedAt >= DateTime.UtcNow.AddDays(-7))
            .Select(x => x.RecipeName)
            .ToListAsync(ct);

        var pantrySnapshot = ingredients
            .Select(x => new GeminiIngredient
            {
                Name = x.Name,
                Quantity = x.Quantity,
                Unit = x.Unit
            })
            .ToList();

        var recentNormalized = new HashSet<string>(
            recentCooked.Select(NormalizeName),
            StringComparer.OrdinalIgnoreCase
        );

        var geminiRecipes = await _gemini.GenerateRecipesAsync(
            pantrySnapshot,
            recentCooked,
            PantryRecipeCount,
            normalizedTab == "near" ? "near" : normalizedTab == "full" ? "full" : "mixed",
            ct
        );

        var result = BuildSuggestions(
            geminiRecipes,
            pantrySnapshot,
            recentNormalized
        );

        if (normalizedTab == "full" && result.FullRecipes.Count < PantryRecipeCount)
        {
            var missing = PantryRecipeCount - result.FullRecipes.Count;
            await FillMissingAsync(
                result,
                pantrySnapshot,
                recentCooked,
                recentNormalized,
                "full",
                missing,
                ct
            );
        }

        if (normalizedTab == "near" && result.NearRecipes.Count < PantryRecipeCount)
        {
            var missing = PantryRecipeCount - result.NearRecipes.Count;
            await FillMissingAsync(
                result,
                pantrySnapshot,
                recentCooked,
                recentNormalized,
                "near",
                missing,
                ct
            );
            if (result.NearRecipes.Count < PantryRecipeCount && result.FullRecipes.Count > 0)
            {
                MergeSuggestions(result.NearRecipes, result.FullRecipes, PantryRecipeCount);
            }
        }
        Cache(cacheKey, result);
        CacheRefresh(cacheKey, result);

        var query = new RecipeQuery
        {
            UserId = userId,
            IngredientsSnapshot = JsonSerializer.Serialize(pantrySnapshot),
            AiProvider = "Gemini",
            CreatedAt = DateTime.UtcNow
        };
        _db.RecipeQueries.Add(query);
        await _db.SaveChangesAsync(ct);

        return FilterResponseByTab(result, normalizedTab);
    }

    private RecipeSuggestionsResponse BuildSuggestions(
        List<GeminiRecipe> pantryRecipes,
        List<GeminiIngredient> pantry,
        HashSet<string> recentNormalized)
    {
        var pantryNames = pantry
            .Select(x => NormalizeName(x.Name))
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var full = new List<RecipeSuggestionDto>();
        var near = new List<RecipeSuggestionDto>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var recipe in pantryRecipes)
        {
            var name = (recipe.Name ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                continue;
            }

            var normalized = NormalizeName(name);
            if (recentNormalized.Contains(normalized) || !seen.Add(normalized))
            {
                continue;
            }

            var ingredients = recipe.Ingredients
                .Where(x => !string.IsNullOrWhiteSpace(x.Name))
                .Select(x => new RecipeIngredientDto
                {
                    Name = x.Name.Trim(),
                    Quantity = x.Quantity <= 0 ? 1 : x.Quantity,
                    Unit = x.Unit?.Trim() ?? ""
                })
                .ToList();

            if (ingredients.Count == 0)
            {
                continue;
            }

            var missing = ingredients
                .Where(x => !IsIngredientAvailable(x.Name, pantryNames))
                .ToList();

            var ratio = (double)missing.Count / ingredients.Count;
            if (missing.Count == 0)
            {
                full.Add(MapSuggestion(recipe, ingredients, missing));
            }
            else if (ratio <= 1.0 / 3.0)
            {
                near.Add(MapSuggestion(recipe, ingredients, missing));
            }
        }

        return new RecipeSuggestionsResponse
        {
            GeneratedAt = DateTime.UtcNow,
            FullRecipes = full,
            NearRecipes = near
        };
    }

    private async Task FillMissingAsync(
        RecipeSuggestionsResponse current,
        List<GeminiIngredient> pantrySnapshot,
        List<string> recentCooked,
        HashSet<string> recentNormalized,
        string mode,
        int missing,
        CancellationToken ct)
    {
        if (missing <= 0)
        {
            return;
        }

        var extraRecipes = await _gemini.GenerateRecipesAsync(
            pantrySnapshot,
            recentCooked,
            missing,
            mode,
            ct
        );

        var extra = BuildSuggestions(extraRecipes, pantrySnapshot, recentNormalized);
        if (mode == "full")
        {
            MergeSuggestions(current.FullRecipes, extra.FullRecipes, PantryRecipeCount);
        }
        else if (mode == "near")
        {
            MergeSuggestions(current.NearRecipes, extra.NearRecipes, PantryRecipeCount);
        }
    }

    private static void MergeSuggestions(
        List<RecipeSuggestionDto> target,
        List<RecipeSuggestionDto> source,
        int maxCount)
    {
        var seen = new HashSet<string>(
            target.Select(x => NormalizeName(x.Name)),
            StringComparer.OrdinalIgnoreCase
        );

        foreach (var item in source)
        {
            var key = NormalizeName(item.Name);
            if (string.IsNullOrWhiteSpace(key) || !seen.Add(key))
            {
                continue;
            }

            target.Add(item);
            if (target.Count >= maxCount)
            {
                break;
            }
        }
    }

    private static RecipeSuggestionDto MapSuggestion(
        GeminiRecipe recipe,
        List<RecipeIngredientDto> ingredients,
        List<RecipeIngredientDto> missing)
    {
        return new RecipeSuggestionDto
        {
            Name = recipe.Name.Trim(),
            TimeMinutes = recipe.TimeMinutes <= 0 ? 30 : recipe.TimeMinutes,
            ImageUrl = BuildImageUrl(recipe.ImageUrl, recipe.Name),
            Ingredients = ingredients,
            MissingIngredients = missing
        };
    }

    private static bool IsIngredientAvailable(string ingredientName, List<string> pantryNames)
    {
        var target = NormalizeName(ingredientName);
        if (string.IsNullOrWhiteSpace(target))
        {
            return false;
        }

        foreach (var pantry in pantryNames)
        {
            if (pantry == target)
            {
                return true;
            }
        }

        return false;
    }

    private static string NormalizeName(string value)
    {
        var trimmed = value.Trim().ToLowerInvariant();
        var normalized = trimmed.Normalize(NormalizationForm.FormD);
        var chars = normalized.Where(ch => CharUnicodeInfo.GetUnicodeCategory(ch) != UnicodeCategory.NonSpacingMark);
        var withoutMarks = new string(chars.ToArray()).Normalize(NormalizationForm.FormC);
        var cleaned = new string(withoutMarks.Select(ch => char.IsLetterOrDigit(ch) ? ch : ' ').ToArray());
        return string.Join(' ', cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }

    private static string BuildCacheKey(Guid userId, DateTime utcNow, string tab)
    {
        var date = utcNow.ToString("yyyy-MM-dd");
        return $"{userId:N}:{date}:{tab}";
    }

    private static void Cache(string key, RecipeSuggestionsResponse response)
    {
        lock (_cacheLock)
        {
            _cache[key] = new CacheEntry(response);
        }
    }

    private static void CacheRefresh(string key, RecipeSuggestionsResponse response)
    {
        lock (_cacheLock)
        {
            _refreshCache[key] = new TimedCacheEntry(response, DateTime.UtcNow);
        }
    }

    private static bool TryGetCached(string key, out RecipeSuggestionsResponse response)
    {
        lock (_cacheLock)
        {
            if (_cache.TryGetValue(key, out var entry))
            {
                response = entry.Response;
                return true;
            }
        }

        response = new RecipeSuggestionsResponse();
        return false;
    }

    private static bool TryGetRefreshCached(string key, out RecipeSuggestionsResponse response)
    {
        lock (_cacheLock)
        {
            if (_refreshCache.TryGetValue(key, out var entry))
            {
                var age = DateTime.UtcNow - entry.CreatedAt;
                if (age.TotalSeconds <= RefreshCacheSeconds)
                {
                    response = entry.Response;
                    return true;
                }
                _refreshCache.Remove(key);
            }
        }

        response = new RecipeSuggestionsResponse();
        return false;
    }

    private static string NormalizeTab(string? tab)
    {
        var value = (tab ?? string.Empty).Trim().ToLowerInvariant();
        return value switch
        {
            "full" => "full",
            "near" => "near",
            _ => "all"
        };
    }

    private static RecipeSuggestionsResponse FilterResponseByTab(
        RecipeSuggestionsResponse source,
        string tab)
    {
        if (tab == "all") return source;

        return new RecipeSuggestionsResponse
        {
            GeneratedAt = source.GeneratedAt,
            FullRecipes = tab == "full" ? source.FullRecipes : new List<RecipeSuggestionDto>(),
            NearRecipes = tab == "near" ? source.NearRecipes : new List<RecipeSuggestionDto>()
        };
    }

    private static string BuildImageUrl(string? url, string recipeName)
    {
        var trimmed = (url ?? string.Empty).Trim();
        if (trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return trimmed;
        }

        var query = Uri.EscapeDataString(recipeName);
        return $"https://source.unsplash.com/featured/?{query}";
    }

    private sealed class CacheEntry
    {
        public CacheEntry(RecipeSuggestionsResponse response)
        {
            Response = response;
        }

        public RecipeSuggestionsResponse Response { get; }
    }

    private sealed class TimedCacheEntry
    {
        public TimedCacheEntry(RecipeSuggestionsResponse response, DateTime createdAt)
        {
            Response = response;
            CreatedAt = createdAt;
        }

        public RecipeSuggestionsResponse Response { get; }
        public DateTime CreatedAt { get; }
    }
}
