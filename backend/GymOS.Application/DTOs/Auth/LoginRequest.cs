namespace GymOS.Application.DTOs.Auth;

public class LoginRequest
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}