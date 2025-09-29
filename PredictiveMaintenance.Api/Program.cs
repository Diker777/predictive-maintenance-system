using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Api.Hubs;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();

// Database configuration
var dbSection = builder.Configuration.GetSection("Database");
var provider = dbSection.GetValue<string>("Provider")?.ToLowerInvariant();
var sqlServerCnn = dbSection.GetSection("ConnectionStrings").GetValue<string>("SqlServer");
var mySqlCnn = dbSection.GetSection("ConnectionStrings").GetValue<string>("MySql");

if (provider == "mysql")
{
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseMySql(mySqlCnn, ServerVersion.AutoDetect(mySqlCnn)));
}
else
{
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseSqlServer(sqlServerCnn));
}

builder.Services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());
builder.Services.AddScoped<IThresholdEvaluator, ThresholdEvaluator>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors(policy => policy
    .AllowAnyHeader()
    .AllowAnyMethod()
    .AllowCredentials()
    .SetIsOriginAllowed(_ => true));

app.MapControllers();
app.MapHub<AlertsHub>("/hubs/alerts");

// Apply migrations and seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await PredictiveMaintenance.Infrastructure.DbInitializer.SeedAsync(db);
}

app.Run();
