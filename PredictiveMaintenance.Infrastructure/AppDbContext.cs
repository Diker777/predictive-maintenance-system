using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Infrastructure;

public class AppDbContext : DbContext, IAppDbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Device> Devices => Set<Device>();
    public DbSet<SensorReading> SensorReadings => Set<SensorReading>();
    public DbSet<ThresholdRule> ThresholdRules => Set<ThresholdRule>();
    public DbSet<Alert> Alerts => Set<Alert>();

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Device>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.HasMany(x => x.Readings)
                  .WithOne(r => r.Device!)
                  .HasForeignKey(r => r.DeviceId)
                  .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(x => x.ThresholdRules)
                  .WithOne(r => r.Device!)
                  .HasForeignKey(r => r.DeviceId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SensorReading>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.DeviceId, x.Metric, x.TimestampUtc });
        });

        modelBuilder.Entity<ThresholdRule>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Severity).HasDefaultValue(1);
        });

        modelBuilder.Entity<Alert>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.DeviceId, x.Metric, x.CreatedUtc });
            entity.Property(x => x.Message).HasMaxLength(1000);
        });
    }
}


