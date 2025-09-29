using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Application.Abstractions;

public interface IAppDbContext
{
    DbSet<Device> Devices { get; }
    DbSet<SensorReading> SensorReadings { get; }
    DbSet<ThresholdRule> ThresholdRules { get; }
    DbSet<Alert> Alerts { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

public interface IThresholdEvaluator
{
    Task<IReadOnlyList<Alert>> EvaluateAsync(SensorReading reading, CancellationToken ct = default);
}


