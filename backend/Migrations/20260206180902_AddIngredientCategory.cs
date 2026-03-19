using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddIngredientCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add Category column only if it does not already exist (idempotent)
            migrationBuilder.Sql(@"DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Ingredients' AND column_name = 'Category'
    ) THEN
        ALTER TABLE ""Ingredients"" ADD COLUMN ""Category"" character varying(30) NOT NULL DEFAULT '';
    END IF;
END
$$;", true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Category",
                table: "Ingredients");
        }
    }
}
