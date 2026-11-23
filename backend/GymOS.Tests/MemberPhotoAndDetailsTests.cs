using System.Text;
using System.Text.Json;
using GymOS.Application.Features.Members.Commands.CreateMember;
using GymOS.Application.Features.Members.Commands.DeleteMemberPhoto;
using GymOS.Application.Features.Members.Commands.UpdateMember;
using GymOS.Application.Features.Members.Commands.UploadMemberPhoto;
using GymOS.Application.Features.Members.Queries.GetMemberById;
using GymOS.Application.Features.Members.Queries.GetMembers;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using GymOS.Infrastructure.Data;
using GymOS.Infrastructure.Services;
using GymOS.Tests.Helpers;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
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

    private (GymDbContext DbContext, UserManager<ApplicationUser> UserManager, TestTenantService TenantService) SetupEnvironment(Guid gymId)
    {
        var services = new ServiceCollection();
        services.AddLogging(b => b.AddConsole());

        var db = TestDbContextFactory.Create(gymId.ToString());
        var tenantService = new TestTenantService(gymId.ToString());

        services.AddSingleton(db);
        services.AddIdentity<ApplicationUser, IdentityRole>()
            .AddEntityFrameworkStores<GymDbContext>()
            .AddDefaultTokenProviders();

        var sp = services.BuildServiceProvider();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();

        return (db, userManager, tenantService);
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

        // Verify JSON serialization includes exact "photoUrl" field
        var json = System.Text.Json.JsonSerializer.Serialize(item);
        Assert.Contains("\"photoUrl\":", json);
    }

    [Fact]
    public async Task CreateMember_WithDifferentGenders_PersistsAndQueriesCorrectly()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var (context, userManager, tenantService) = SetupEnvironment(tenantId);
        var createHandler = new CreateMemberCommandHandler(userManager, context, tenantService);
        var getByIdHandler = new GetMemberByIdQueryHandler(context, tenantService);
        var getMembersHandler = new GetMembersQueryHandler(context);

        // 1. Create member with default Gender.Unspecified
        var cmdUnspecified = new CreateMemberCommand("عضو بدون تحديد", "01000000001");
        var idUnspecified = await createHandler.Handle(cmdUnspecified, CancellationToken.None);

        // 2. Create member with Gender.Male
        var cmdMale = new CreateMemberCommand("عضو ذكر", "01000000002", Gender: Gender.Male);
        var idMale = await createHandler.Handle(cmdMale, CancellationToken.None);

        // 3. Create member with Gender.Female
        var cmdFemale = new CreateMemberCommand("عضوة أنثى", "01000000003", Gender: Gender.Female);
        var idFemale = await createHandler.Handle(cmdFemale, CancellationToken.None);

        // Act & Assert - GetMemberById
        var dtoUnspecified = await getByIdHandler.Handle(new GetMemberByIdQuery(idUnspecified), CancellationToken.None);
        var dtoMale = await getByIdHandler.Handle(new GetMemberByIdQuery(idMale), CancellationToken.None);
        var dtoFemale = await getByIdHandler.Handle(new GetMemberByIdQuery(idFemale), CancellationToken.None);

        Assert.NotNull(dtoUnspecified);
        Assert.Equal(Gender.Unspecified, dtoUnspecified.Gender);
        var jsonUnspecified = JsonSerializer.Serialize(dtoUnspecified);
        Assert.Contains("\"gender\":0", jsonUnspecified);

        Assert.NotNull(dtoMale);
        Assert.Equal(Gender.Male, dtoMale.Gender);
        var jsonMale = JsonSerializer.Serialize(dtoMale);
        Assert.Contains("\"gender\":1", jsonMale);

        Assert.NotNull(dtoFemale);
        Assert.Equal(Gender.Female, dtoFemale.Gender);
        var jsonFemale = JsonSerializer.Serialize(dtoFemale);
        Assert.Contains("\"gender\":2", jsonFemale);

        // Act & Assert - GetMembers list
        var listResult = await getMembersHandler.Handle(new GetMembersQuery(PageSize: 10), CancellationToken.None);
        Assert.Equal(3, listResult.Items.Count);

        var listMemberMale = listResult.Items.First(m => m.Id == idMale);
        Assert.Equal(Gender.Male, listMemberMale.Gender);

        var listMemberFemale = listResult.Items.First(m => m.Id == idFemale);
        Assert.Equal(Gender.Female, listMemberFemale.Gender);
    }

    [Fact]
    public async Task UpdateMember_Gender_UpdatesSuccessfullyAndReflectedInQuery()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var (context, userManager, tenantService) = SetupEnvironment(tenantId);
        var createHandler = new CreateMemberCommandHandler(userManager, context, tenantService);
        var updateHandler = new UpdateMemberCommandHandler(context, tenantService);
        var getByIdHandler = new GetMemberByIdQueryHandler(context, tenantService);

        var memberId = await createHandler.Handle(new CreateMemberCommand("سارة أحمد", "01055554444", Gender: Gender.Unspecified), CancellationToken.None);

        // Act - Update to Female
        var updateResult = await updateHandler.Handle(
            new UpdateMemberCommand(memberId, "سارة أحمد المعدلة", "01055554444", Gender: Gender.Female),
            CancellationToken.None);

        // Assert
        Assert.True(updateResult.IsSuccess);
        Assert.NotNull(updateResult.Member);
        Assert.Equal(Gender.Female, updateResult.Member.Gender);

        var queried = await getByIdHandler.Handle(new GetMemberByIdQuery(memberId), CancellationToken.None);
        Assert.NotNull(queried);
        Assert.Equal(Gender.Female, queried.Gender);
    }

    [Fact]
    public async Task ReplaceMemberPhoto_DeletesOldPhotoFileFromDisk_KeepsNewFileIntact()
    {
        // Arrange
        var tempDir = Path.Combine(Path.GetTempPath(), "gymos_test_" + Guid.NewGuid().ToString("N"));
        var uploadsDir = Path.Combine(tempDir, "wwwroot", "uploads");
        Directory.CreateDirectory(uploadsDir);

        try
        {
            // Switch current directory to tempDir during this test so LocalFileStorageService resolves paths correctly
            var originalCurrentDirectory = Directory.GetCurrentDirectory();
            Directory.SetCurrentDirectory(tempDir);

            try
            {
                var storageService = new LocalFileStorageService();
                var tenantId = Guid.NewGuid();
                var context = TestDbContextFactory.Create(tenantId.ToString());
                var tenantService = new TestTenantService(tenantId.ToString());

                // Upload 1st photo
                var firstBytes = Encoding.UTF8.GetBytes("first-photo-data");
                using var firstStream = new MemoryStream(firstBytes);
                var memberId = "mem_disk_replace_test";
                var firstRelativePath = $"members/{tenantId}/{memberId}_photo1.jpg";
                var firstUrl = await storageService.UploadFileAsync(firstStream, firstRelativePath, CancellationToken.None);

                var firstPhysicalPath = Path.Combine(tempDir, "wwwroot", firstUrl.TrimStart('/'));
                Assert.True(File.Exists(firstPhysicalPath), "First photo must exist on disk before replacement.");

                // Create member entity with firstUrl
                var member = new ApplicationUser
                {
                    Id = memberId,
                    TenantId = tenantId,
                    FullName = "عضو اختبار استبدال الصورة",
                    PhoneNumber = "01088887777",
                    PhotoUrl = firstUrl,
                    Type = UserType.Member
                };
                context.Users.Add(member);
                await context.SaveChangesAsync();

                var handler = new UploadMemberPhotoCommandHandler(context, tenantService, storageService);

                // Act - Upload 2nd photo (replace)
                var secondBytes = Encoding.UTF8.GetBytes("second-photo-data-new");
                using var secondStream = new MemoryStream(secondBytes);
                var uploadCmd = new UploadMemberPhotoCommand(member.Id, secondStream, "new_photo.png", secondBytes.Length);

                var result = await handler.Handle(uploadCmd, CancellationToken.None);

                // Assert
                Assert.True(result.IsSuccess);
                Assert.NotNull(result.PhotoUrl);
                Assert.NotEqual(firstUrl, result.PhotoUrl);

                var secondPhysicalPath = Path.Combine(tempDir, "wwwroot", result.PhotoUrl.TrimStart('/'));

                // Verify old photo was deleted from disk and new photo exists on disk intact
                Assert.False(File.Exists(firstPhysicalPath), "Old photo should be deleted from disk.");
                Assert.True(File.Exists(secondPhysicalPath), "New photo should remain on disk.");
                Assert.Equal(secondBytes, await File.ReadAllBytesAsync(secondPhysicalPath));
            }
            finally
            {
                Directory.SetCurrentDirectory(originalCurrentDirectory);
            }
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                try { Directory.Delete(tempDir, true); } catch { }
            }
        }
    }

    [Fact]
    public async Task DeleteMemberPhoto_DeletesFileFromDisk_AndSetsPhotoUrlToNull()
    {
        // Arrange
        var tempDir = Path.Combine(Path.GetTempPath(), "gymos_delete_photo_test_" + Guid.NewGuid().ToString("N"));
        var uploadsDir = Path.Combine(tempDir, "wwwroot", "uploads");
        Directory.CreateDirectory(uploadsDir);

        try
        {
            var originalCurrentDirectory = Directory.GetCurrentDirectory();
            Directory.SetCurrentDirectory(tempDir);

            try
            {
                var storageService = new LocalFileStorageService();
                var tenantId = Guid.NewGuid();
                var context = TestDbContextFactory.Create(tenantId.ToString());
                var tenantService = new TestTenantService(tenantId.ToString());

                // Upload a photo
                var photoBytes = Encoding.UTF8.GetBytes("photo-to-be-deleted");
                using var photoStream = new MemoryStream(photoBytes);
                var memberId = "mem_delete_photo_test";
                var relativePath = $"members/{tenantId}/{memberId}_photo.jpg";
                var photoUrl = await storageService.UploadFileAsync(photoStream, relativePath, CancellationToken.None);

                var physicalPath = Path.Combine(tempDir, "wwwroot", photoUrl.TrimStart('/'));
                Assert.True(File.Exists(physicalPath), "Photo must exist on disk before deletion.");

                var member = new ApplicationUser
                {
                    Id = memberId,
                    TenantId = tenantId,
                    FullName = "عضو اختبار حذف الصورة",
                    PhoneNumber = "01012349876",
                    PhotoUrl = photoUrl,
                    Type = UserType.Member
                };
                context.Users.Add(member);
                await context.SaveChangesAsync();

                var deleteHandler = new DeleteMemberPhotoCommandHandler(context, tenantService, storageService);
                var getByIdHandler = new GetMemberByIdQueryHandler(context, tenantService);

                // Act
                var result = await deleteHandler.Handle(new DeleteMemberPhotoCommand(memberId), CancellationToken.None);

                // Assert
                Assert.True(result.IsSuccess);
                Assert.Equal(200, result.StatusCode);

                // Verify file deleted from disk
                Assert.False(File.Exists(physicalPath), "Photo file must be deleted from disk.");

                // Verify PhotoUrl is null in DB
                var updatedUser = await context.Users.FindAsync(memberId);
                Assert.NotNull(updatedUser);
                Assert.Null(updatedUser.PhotoUrl);

                // Verify GetMemberById returns null PhotoUrl
                var dto = await getByIdHandler.Handle(new GetMemberByIdQuery(memberId), CancellationToken.None);
                Assert.NotNull(dto);
                Assert.Null(dto.PhotoUrl);
            }
            finally
            {
                Directory.SetCurrentDirectory(originalCurrentDirectory);
            }
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                try { Directory.Delete(tempDir, true); } catch { }
            }
        }
    }
}
