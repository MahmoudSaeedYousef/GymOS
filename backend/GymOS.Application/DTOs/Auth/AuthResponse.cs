namespace GymOS.Application.DTOs.Auth;

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
}