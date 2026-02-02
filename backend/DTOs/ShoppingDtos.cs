namespace Backend.DTOs;

public class ShoppingItemResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public bool IsChecked { get; set; }
}

public class ShoppingListResponse
{
    public Guid Id { get; set; }
    public List<ShoppingItemResponse> Items { get; set; } = new();
}

public class ShoppingItemCreateRequest
{
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
}

public class ShoppingItemUpdateRequest
{
    public string Name { get; set; } = "";
    public double Quantity { get; set; }
    public string Unit { get; set; } = "";
    public bool IsChecked { get; set; }
}