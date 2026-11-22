using System.Text;
using GymOS.Application.Features.Members.Commands.UpdateMember;
using GymOS.Application.Features.Members.Commands.UploadMemberPhoto;
using GymOS.Application.Features.Members.Queries.GetMembers;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Tests.Helpers;
using Xunit;

namespace GymOS.Tests;

public class MemberPhotoAndDetailsTests
{
    private class FakeFileStorageService : IFileStorageService
    {
        public List<string> DeletedFiles { get; } = new();
        public List<string> UploadedFiles { get; } = new();

        public Task<string> UploadFileAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
        {
            var relativePath = $"/uploads/{fileName.TrimStart('/')}";
            UploadedFiles.Add(relativePath);
            return Task.FromResult(relativePath);
        }

        public Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
        {
            DeletedFiles.Add(fileUrl);
            return Task.CompletedTask;
        }
    }

    [Fact]
    public async Task UpdateMemberDetails_WithValidData_UpdatesMemberSuccessfully()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());

        var member = new ApplicationUser
        {
            Id = "mem_update_1",
            TenantId = tenantId,
            FullName = "الاسم القديم",
            PhoneNumber = "01011112222",
            Type = UserType.Member,
            IsGuest = false
        };
        context.Users.Add(member);
        await context.SaveChangesAsync();

        var handler = new UpdateMemberCommandHandler(context, tenantService);
        var command = new UpdateMemberCommand(member.Id, "نور الهواري صلاح", "01012940480");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.Equal(200, result.StatusCode);
        Assert.NotNull(result.Member);
        Assert.Equal("نور الهواري صلاح", result.Member.FullName);
        Assert.Equal("01012940480", result.Member.PhoneNumber);

        var updatedMember = await context.Users.FindAsync(member.Id);
        Assert.NotNull(updatedMember);
        Assert.Equal("نور الهواري صلاح", updatedMember.FullName);
        Assert.Equal("01012940480", updatedMember.PhoneNumber);
        Assert.Equal($"{tenantId}_01012940480", updatedMember.UserName);
    }

    [Fact]
    public async Task UpdateMemberDetails_WithDuplicatePhoneNumber_ReturnsBadRequest()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());

        var member1 = new ApplicationUser
        {
            Id = "mem_dup_1",
            TenantId = tenantId,
            FullName = "المشترك الأول",
            PhoneNumber = "01011112222",
            Type = UserType.Member
        };
        var member2 = new ApplicationUser
        {
            Id = "mem_dup_2",
            TenantId = tenantId,
            FullName = "المشترك الثاني",
            PhoneNumber = "01033334444",
            Type = UserType.Member
        };
        context.Users.AddRange(member1, member2);
        await context.SaveChangesAsync();

        var handler = new UpdateMemberCommandHandler(context, tenantService);
        var command = new UpdateMemberCommand(member1.Id, "الاسم الجديد", "01033334444");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("already in use", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task UpdateMemberDetails_WithEmptyFields_ReturnsBadRequest()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());

        var handler = new UpdateMemberCommandHandler(context, tenantService);

        // Act & Assert
        var emptyNameResult = await handler.Handle(new UpdateMemberCommand("mem_1", "", "01012345678"), CancellationToken.None);
        Assert.False(emptyNameResult.IsSuccess);
        Assert.Equal(400, emptyNameResult.StatusCode);

        var emptyPhoneResult = await handler.Handle(new UpdateMemberCommand("mem_1", "اسم العضو", "  "), CancellationToken.None);
        Assert.False(emptyPhoneResult.IsSuccess);
        Assert.Equal(400, emptyPhoneResult.StatusCode);
    }

    [Fact]
    public async Task UpdateMemberDetails_WithDifferentTenant_ReturnsNotFound()
    {
        // Arrange
        var tenant1 = Guid.NewGuid();
        var tenant2 = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenant1.ToString());
        var tenantService = new TestTenantService(tenant2.ToString());

        var member = new ApplicationUser
        {
            Id = "mem_other_tenant",
            TenantId = tenant1,
            FullName = "عضو بجيم آخر",
            PhoneNumber = "01055556666",
            Type = UserType.Member
        };
        context.Users.Add(member);
        await context.SaveChangesAsync();

        var handler = new UpdateMemberCommandHandler(context, tenantService);
        var result = await handler.Handle(new UpdateMemberCommand(member.Id, "اسم معدل", "01077778888"), CancellationToken.None);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal(404, result.StatusCode);
    }

    [Fact]
    public async Task UploadMemberPhoto_ValidPhoto_SavesUrlAndDeletesOldPhoto()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());
        var fileStorage = new FakeFileStorageService();

        var member = new ApplicationUser
        {
            Id = "mem_photo_1",
            TenantId = tenantId,
            FullName = "عضو مع صورة قديمة",
            PhoneNumber = "01099991111",
            PhotoUrl = $"/uploads/members/{tenantId}/old_photo.jpg",
            Type = UserType.Member
        };
        context.Users.Add(member);
        await context.SaveChangesAsync();

        var handler = new UploadMemberPhotoCommandHandler(context, tenantService, fileStorage);

        var bytes = Encoding.UTF8.GetBytes("fake-image-bytes");
        using var stream = new MemoryStream(bytes);

        var command = new UploadMemberPhotoCommand(member.Id, stream, "avatar.png", bytes.Length);

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.NotNull(result.PhotoUrl);
        Assert.StartsWith($"/uploads/members/{tenantId}/{member.Id}_", result.PhotoUrl);
        Assert.EndsWith(".png", result.PhotoUrl);

        // Verify old file was requested to delete
        Assert.Single(fileStorage.DeletedFiles);
        Assert.Equal($"/uploads/members/{tenantId}/old_photo.jpg", fileStorage.DeletedFiles[0]);

        // Verify entity updated
        var updatedMember = await context.Users.FindAsync(member.Id);
        Assert.NotNull(updatedMember);
        Assert.Equal(result.PhotoUrl, updatedMember.PhotoUrl);
    }

    [Fact]
    public async Task UploadMemberPhoto_InvalidExtension_ReturnsBadRequest()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());
        var fileStorage = new FakeFileStorageService();

        var handler = new UploadMemberPhotoCommandHandler(context, tenantService, fileStorage);
        using var stream = new MemoryStream(new byte[] { 1, 2, 3 });

        var command = new UploadMemberPhotoCommand("mem_1", stream, "danger.exe", 3);

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("Invalid file extension", result.ErrorMessage);
    }

    [Fact]
    public async Task UploadMemberPhoto_ExceedingSizeLimit_ReturnsBadRequest()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());
        var tenantService = new TestTenantService(tenantId.ToString());
        var fileStorage = new FakeFileStorageService();

        var handler = new UploadMemberPhotoCommandHandler(context, tenantService, fileStorage);
        using var stream = new MemoryStream();

        const long over5Mb = 5 * 1024 * 1024 + 1;
        var command = new UploadMemberPhotoCommand("mem_1", stream, "huge.jpg", over5Mb);

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("exceeds 5 MB", result.ErrorMessage);
    }

    [Fact]
    public async Task GetMembers_IncludesPhotoUrlInResponse()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var memberWithPhoto = new ApplicationUser
        {
            Id = "mem_photo_test",
            TenantId = tenantId,
            FullName = "عضو مع صورة",
            PhoneNumber = "01011119999",
            PhotoUrl = $"/uploads/members/{tenantId}/pic.webp",
            Type = UserType.Member,
            IsGuest = false
        };
        context.Users.Add(memberWithPhoto);
        await context.SaveChangesAsync();

        var handler = new GetMembersQueryHandler(context);

        // Act
        var result = await handler.Handle(new GetMembersQuery(), CancellationToken.None);

        // Assert
        var item = Assert.Single(result.Items);
        Assert.Equal($"/uploads/members/{tenantId}/pic.webp", item.PhotoUrl);
    }
}
