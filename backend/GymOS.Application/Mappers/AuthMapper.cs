using GymOS.Application.DTOs.Auth;
using GymOS.Domain.Entities;
using Riok.Mapperly.Abstractions;

namespace GymOS.Application.Mappers;

[Mapper]
public partial class AuthMapper
{
    // بنقول للـ Mapper يتجاهل الحقول اللي مش في الـ DTO عشان مايطلعش Warnings
    [MapperIgnoreTarget(nameof(ApplicationUser.Id))]
    [MapperIgnoreTarget(nameof(ApplicationUser.UserName))]
    [MapperIgnoreTarget(nameof(ApplicationUser.Type))]
    public partial ApplicationUser RegisterRequestToUser(RegisterRequest request);
}