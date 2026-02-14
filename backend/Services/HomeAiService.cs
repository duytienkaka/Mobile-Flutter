using System.Globalization;
using System.Text;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class HomeAiService
{
    private readonly AppDbContext _db;
    private readonly RecipeSuggestionService _recipes;
    private readonly GeminiService _gemini;

    private static readonly object _cacheLock = new();
    private static readonly Dictionary<string, HomeAiCacheEntry> _cache = new();

    public HomeAiService(AppDbContext db, RecipeSuggestionService recipes, GeminiService gemini)
    {
        _db = db;
        _recipes = recipes;
        _gemini = gemini;
    }

    public async Task<HomeAiResponse> GetHomeAiAsync(
        Guid userId,
        bool refresh,
        CancellationToken ct)
    {
        var cacheKey = BuildCacheKey(userId, DateTime.UtcNow);
        if (!refresh && TryGetCached(cacheKey, out var cached))
        {
            return cached;
        }

        var recipeResponse = await _recipes.GetTodaySuggestions(userId, refresh, "full", ct);
        if (recipeResponse.FullRecipes.Count == 0 && !refresh)
        {
            recipeResponse = await _recipes.GetTodaySuggestions(userId, true, "full", ct);
        }

        var ingredients = await _db.Ingredients
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .ToListAsync(ct);

        var categorized = BuildCategoryMap(ingredients);
        var tips = new List<HomeTipDto>();
        if (categorized.Count > 0)
        {
            var rawTips = await _gemini.GenerateStorageTipsAsync(categorized, ct);
            tips = FilterTips(rawTips, categorized.Keys);
        }

        var response = new HomeAiResponse
        {
            GeneratedAt = DateTime.UtcNow,
            RecommendedRecipes = recipeResponse.FullRecipes,
            StorageTips = tips
        };

        Cache(cacheKey, response);
        return response;
    }

    private static Dictionary<string, List<string>> BuildCategoryMap(
        List<Ingredient> ingredients)
    {
        var map = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        foreach (var ingredient in ingredients)
        {
            var group = MapToGroup(ingredient.Category, ingredient.Name);
            if (group == null)
            {
                continue;
            }

            if (!map.TryGetValue(group, out var list))
            {
                list = new List<string>();
                map[group] = list;
            }

            var name = ingredient.Name.Trim();
            if (!string.IsNullOrWhiteSpace(name) && !list.Any(x =>
                    x.Equals(name, StringComparison.OrdinalIgnoreCase)))
            {
                list.Add(name);
            }
        }

        foreach (var key in map.Keys.ToList())
        {
            map[key] = map[key].Take(10).ToList();
        }

        return map;
    }

    private static string? MapToGroup(string? category, string name)
    {
        var source = string.IsNullOrWhiteSpace(category) ? name : category;
        var normalized = NormalizeValue(source);
        if (normalized.Length == 0)
        {
            return null;
        }

        if (normalized.Contains("fruit") || normalized.Contains("trai") || normalized.Contains("qua"))
        {
            return "fruit";
        }

        if (normalized.Contains("vegetable") || normalized.Contains("rau") || normalized.Contains("cu"))
        {
            return "vegetable";
        }

        if (normalized.Contains("meat") || normalized.Contains("thit") || normalized.Contains("seafood") ||
            normalized.Contains("hai san") || normalized.Contains("ca") || normalized.Contains("bo") ||
            normalized.Contains("heo") || normalized.Contains("ga"))
        {
            return "meat";
        }

        return null;
    }

    private static string NormalizeValue(string value)
    {
        var trimmed = value.Trim().ToLowerInvariant();
        var normalized = trimmed.Normalize(NormalizationForm.FormD);
        var chars = normalized.Where(ch => CharUnicodeInfo.GetUnicodeCategory(ch) != UnicodeCategory.NonSpacingMark);
        var withoutMarks = new string(chars.ToArray()).Normalize(NormalizationForm.FormC);
        var cleaned = new string(withoutMarks.Select(ch => char.IsLetterOrDigit(ch) ? ch : ' ').ToArray());
        return string.Join(' ', cleaned.Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }

    private static List<HomeTipDto> FilterTips(
        List<GeminiStorageTip> tips,
        IEnumerable<string> categories)
    {
        var allowed = new HashSet<string>(categories, StringComparer.OrdinalIgnoreCase);
        var result = new List<HomeTipDto>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var tip in tips)
        {
            var category = (tip.Category ?? string.Empty).Trim().ToLowerInvariant();
            if (!allowed.Contains(category) || !seen.Add(category))
            {
                continue;
            }

            var title = (tip.Title ?? string.Empty).Trim();
            var message = (tip.Message ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(message))
            {
                continue;
            }

            result.Add(new HomeTipDto
            {
                Category = category,
                Title = title,
                Message = message
            });
        }

        return result;
    }

    private static string BuildCacheKey(Guid userId, DateTime utcNow)
    {
        var date = utcNow.ToString("yyyy-MM-dd");
        return $"{userId:N}:{date}:home-ai";
    }

    private static void Cache(string key, HomeAiResponse response)
    {
        lock (_cacheLock)
        {
            _cache[key] = new HomeAiCacheEntry(response);
        }
    }

    private static bool TryGetCached(string key, out HomeAiResponse response)
    {
        lock (_cacheLock)
        {
            if (_cache.TryGetValue(key, out var entry))
            {
                response = entry.Response;
                return true;
            }
        }

        response = new HomeAiResponse();
        return false;
    }

    private sealed class HomeAiCacheEntry
    {
        public HomeAiCacheEntry(HomeAiResponse response)
        {
            Response = response;
        }

        public HomeAiResponse Response { get; }
    }
}
