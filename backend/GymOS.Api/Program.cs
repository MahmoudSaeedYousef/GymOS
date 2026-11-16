using GymOS.Application.Interfaces;
using GymOS.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// هنا السحر: بنقول للسيستم أي حد يطلب IFileStorageService إديله LocalFileStorageService
builder.Services.AddScoped<IFileStorageService, LocalFileStorageService>();

var app = builder.Build();
app.Run();