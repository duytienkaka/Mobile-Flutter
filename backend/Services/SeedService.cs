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
    }
}
