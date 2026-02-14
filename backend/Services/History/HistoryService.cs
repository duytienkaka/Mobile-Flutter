using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Backend.DTOs.History;

namespace Backend.Services.History;

public class HistoryService
{
	private readonly AppDbContext _db;
	public HistoryService(AppDbContext db)
	{
		_db = db;
	}

	public async Task AddHistoryAsync(Guid userId, string recipeName, string recipeSource, CancellationToken ct)
	{
		var entity = new CookingHistory
		{
			UserId = userId,
			RecipeName = recipeName,
			RecipeSource = recipeSource,
			CookedAt = DateTime.UtcNow
		};
		_db.CookingHistories.Add(entity);
		await _db.SaveChangesAsync(ct);
	}

	public async Task<List<CookingHistoryDto>> GetRecentHistoryAsync(Guid userId, int days, CancellationToken ct)
	{
		var since = DateTime.UtcNow.AddDays(-days);
		return await _db.CookingHistories
			.Where(x => x.UserId == userId && x.CookedAt >= since)
			.OrderByDescending(x => x.CookedAt)
			.Select(x => new CookingHistoryDto
			{
				Id = x.Id,
				RecipeName = x.RecipeName,
				RecipeSource = x.RecipeSource,
				CookedAt = x.CookedAt
			})
			.ToListAsync(ct);
	}

	public async Task<List<string>> GetRecentRecipeNamesAsync(Guid userId, int days, CancellationToken ct)
	{
		var since = DateTime.UtcNow.AddDays(-days);
		return await _db.CookingHistories
			.Where(x => x.UserId == userId && x.CookedAt >= since)
			.Select(x => x.RecipeName)
			.Distinct()
			.ToListAsync(ct);
	}
}
