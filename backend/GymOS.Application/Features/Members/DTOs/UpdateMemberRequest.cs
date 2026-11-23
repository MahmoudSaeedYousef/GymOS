using GymOS.Domain.Enums;

namespace GymOS.Application.Features.Members.DTOs;

public record UpdateMemberRequest(string FullName, string PhoneNumber, Gender? Gender = null);
