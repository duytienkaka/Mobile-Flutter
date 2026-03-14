using Backend.Data;
using Backend.Models;

namespace Backend.Services
{
    public static class SeedService
    {
        public static void SeedUser(AppDbContext context)
        {
            if (!context.Users.Any(x => x.Email == "test@gmail.com"))
            {
                context.Users.Add(new User
                {
                    Email = "test@gmail.com",
                    PasswordHash = PasswordService.Hash("123456"),
                    IsEmailVerified = true
                });

                context.SaveChanges();
            }
        }

        public static void SeedTestIngredients(AppDbContext context)
        {
            var testUser = context.Users.FirstOrDefault(x => x.Email == "test@gmail.com");
            if (testUser == null) return;

            // Add test ingredients with different expiry dates
            var ingredients = new[]
            {
                new Ingredient
                {
                    Name = "Milk",
                    Quantity = 1,
                    Unit = "liter",
                    ExpiredAt = DateTime.UtcNow.AddDays(1), // Expires tomorrow
                    UserId = testUser.Id,
                    Category = "Dairy"
                },
                new Ingredient
                {
                    Name = "Bread",
                    Quantity = 2,
                    Unit = "loaves",
                    ExpiredAt = DateTime.UtcNow.AddDays(2), // Expires in 2 days
                    UserId = testUser.Id,
                    Category = "Bakery"
                },
                new Ingredient
                {
                    Name = "Cheese",
                    Quantity = 1,
                    Unit = "block",
                    ExpiredAt = DateTime.UtcNow.AddDays(-1), // Already expired
                    UserId = testUser.Id,
                    Category = "Dairy"
                }
            };

            foreach (var ingredient in ingredients)
            {
                if (!context.Ingredients.Any(x => x.Name == ingredient.Name && x.UserId == testUser.Id))
                {
                    context.Ingredients.Add(ingredient);
                }
            }

            context.SaveChanges();
            Console.WriteLine("Test ingredients seeded successfully!");
        }
    }
}
