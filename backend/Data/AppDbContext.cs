using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    // ================= DbSets =================
    public DbSet<User> Users => Set<User>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<Ingredient> Ingredients => Set<Ingredient>();
    public DbSet<ShoppingList> ShoppingLists => Set<ShoppingList>();
    public DbSet<ShoppingItem> ShoppingItems => Set<ShoppingItem>();
    public DbSet<CookingHistory> CookingHistories => Set<CookingHistory>();
    public DbSet<RecipeQuery> RecipeQueries => Set<RecipeQuery>();
    public DbSet<MealPlan> MealPlans => Set<MealPlan>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureUser(modelBuilder);
        ConfigureOtpCode(modelBuilder);
        ConfigureIngredient(modelBuilder);
        ConfigureShopping(modelBuilder);
        ConfigureCookingHistory(modelBuilder);
        ConfigureRecipeQuery(modelBuilder);
        ConfigureMealPlan(modelBuilder);
    }

    // =====================================================
    // USER
    // =====================================================
    private static void ConfigureUser(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<User>();

        e.ToTable("Users");

        e.HasKey(x => x.Id);

        e.Property(x => x.FullName)
            .IsRequired()
            .HasMaxLength(100);

        e.Property(x => x.Email)
            .HasMaxLength(100);

        e.Property(x => x.PhoneNumber)
            .HasMaxLength(20);

        // Unique Email (nullable-safe)
        e.HasIndex(x => x.Email)
            .IsUnique()
            .HasFilter("\"Email\" IS NOT NULL");

        // Unique Phone (nullable-safe)
        e.HasIndex(x => x.PhoneNumber)
            .IsUnique()
            .HasFilter("\"PhoneNumber\" IS NOT NULL");

        e.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");
    }

    // =====================================================
    // OTP CODE
    // =====================================================
    private static void ConfigureOtpCode(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<OtpCode>();

        e.ToTable("OtpCodes");

        e.HasKey(x => x.Id);

        e.Property(x => x.PhoneNumber)
            .IsRequired()
            .HasMaxLength(20);

        e.Property(x => x.Code)
            .IsRequired()
            .HasMaxLength(10);

        e.Property(x => x.Purpose)
            .IsRequired()
            .HasMaxLength(20);

        e.HasIndex(x => new { x.PhoneNumber, x.Purpose });

        e.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");
    }

    // =====================================================
    // INGREDIENT
    // =====================================================
    private static void ConfigureIngredient(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<Ingredient>();

        e.ToTable("Ingredients");

        e.HasKey(x => x.Id);

        e.Property(x => x.Name)
            .IsRequired()
            .HasMaxLength(100);

        e.Property(x => x.Unit)
            .HasMaxLength(20);

        e.HasOne(x => x.User)
            .WithMany(u => u.Ingredients)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        e.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");
    }

    // =====================================================
    // SHOPPING LIST + ITEM
    // =====================================================
    private static void ConfigureShopping(ModelBuilder modelBuilder)
    {
        // -------- ShoppingList --------
        var list = modelBuilder.Entity<ShoppingList>();

        list.ToTable("ShoppingLists");

        list.HasKey(x => x.Id);

        list.HasOne(x => x.User)
            .WithMany(u => u.ShoppingLists)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        list.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");

        list.Property(x => x.Name)
            .IsRequired()
            .HasMaxLength(120);

        list.Property(x => x.PlanDate)
            .HasColumnType("timestamp with time zone");

        // -------- ShoppingItem --------
        var item = modelBuilder.Entity<ShoppingItem>();

        item.ToTable("ShoppingItems");

        item.HasKey(x => x.Id);

        item.Property(x => x.Name)
            .IsRequired()
            .HasMaxLength(100);

        item.Property(x => x.Unit)
            .HasMaxLength(20);

        item.HasOne(x => x.ShoppingList)
            .WithMany(l => l.Items)
            .HasForeignKey(x => x.ShoppingListId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    // =====================================================
    // COOKING HISTORY
    // =====================================================
    private static void ConfigureCookingHistory(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<CookingHistory>();

        e.ToTable("CookingHistories");

        e.HasKey(x => x.Id);

        e.Property(x => x.RecipeName)
            .IsRequired()
            .HasMaxLength(150);

        e.Property(x => x.RecipeSource)
            .HasMaxLength(50);

        e.HasOne(x => x.User)
            .WithMany(u => u.CookingHistories)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        e.Property(x => x.CookedAt)
            .HasDefaultValueSql("now()");
    }

    // =====================================================
    // RECIPE QUERY (AI LOG)
    // =====================================================
    private static void ConfigureRecipeQuery(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<RecipeQuery>();

        e.ToTable("RecipeQueries");

        e.HasKey(x => x.Id);

        e.Property(x => x.IngredientsSnapshot)
            .IsRequired();

        e.Property(x => x.AiProvider)
            .HasMaxLength(50);

        e.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        e.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");
    }

    // =====================================================
    // MEAL PLAN
    // =====================================================
    private static void ConfigureMealPlan(ModelBuilder modelBuilder)
    {
        var e = modelBuilder.Entity<MealPlan>();

        e.ToTable("MealPlans");

        e.HasKey(x => x.Id);

        e.Property(x => x.MealType)
            .IsRequired()
            .HasMaxLength(20);

        e.Property(x => x.RecipeName)
            .IsRequired()
            .HasMaxLength(150);

        e.Property(x => x.Note)
            .HasMaxLength(200);

        e.HasOne(x => x.User)
            .WithMany(u => u.MealPlans)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        e.HasIndex(x => new { x.UserId, x.Date });

        e.Property(x => x.CreatedAt)
            .HasDefaultValueSql("now()");
    }
}
