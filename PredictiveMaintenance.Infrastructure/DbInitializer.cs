using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Infrastructure;

public static class DbInitializer
{
    public static async Task SeedAsync(AppDbContext db, CancellationToken ct = default)
    {
        await db.Database.MigrateAsync(ct);

        if (!await db.Devices.AnyAsync(ct))
        {
            var deviceA = new Device { Id = Guid.NewGuid(), Name = "CNC-01", Description = "CNC Line 1" };
            var deviceB = new Device { Id = Guid.NewGuid(), Name = "Press-02", Description = "Press Line 2" };

            await db.Devices.AddRangeAsync(new [] { deviceA, deviceB }, ct);

            var rules = new List<ThresholdRule>
            {
                new ThresholdRule { Id = Guid.NewGuid(), DeviceId = deviceA.Id, Metric = MetricType.CylinderStrokeTime, Operator = ThresholdOperator.GreaterThan, MaxValue = 1.2, Severity = 2, Enabled = true },
                new ThresholdRule { Id = Guid.NewGuid(), DeviceId = deviceA.Id, Metric = MetricType.ShaftTorque, Operator = ThresholdOperator.Between, MinValue = 10, MaxValue = 80, Severity = 3, Enabled = true },
                new ThresholdRule { Id = Guid.NewGuid(), DeviceId = deviceA.Id, Metric = MetricType.Speed, Operator = ThresholdOperator.LessThan, MinValue = 500, Severity = 1, Enabled = true },
                new ThresholdRule { Id = Guid.NewGuid(), DeviceId = deviceB.Id, Metric = MetricType.CylinderStrokeTime, Operator = ThresholdOperator.GreaterThanOrEqual, MaxValue = 1.5, Severity = 4, Enabled = true },
                new ThresholdRule { Id = Guid.NewGuid(), DeviceId = deviceB.Id, Metric = MetricType.ShaftTorque, Operator = ThresholdOperator.GreaterThan, MaxValue = 120, Severity = 5, Enabled = true }
            };
            await db.ThresholdRules.AddRangeAsync(rules, ct);

            var now = DateTime.UtcNow;
            var readings = Enumerable.Range(0, 30).Select(i => new SensorReading
            {
                Id = Guid.NewGuid(),
                DeviceId = deviceA.Id,
                Metric = MetricType.CylinderStrokeTime,
                Value = 1.0 + (i % 5) * 0.05,
                TimestampUtc = now.AddMinutes(-i)
            }).Concat(Enumerable.Range(0, 30).Select(i => new SensorReading
            {
                Id = Guid.NewGuid(),
                DeviceId = deviceA.Id,
                Metric = MetricType.ShaftTorque,
                Value = 20 + (i % 10) * 5,
                TimestampUtc = now.AddMinutes(-i)
            })).Concat(Enumerable.Range(0, 30).Select(i => new SensorReading
            {
                Id = Guid.NewGuid(),
                DeviceId = deviceA.Id,
                Metric = MetricType.Speed,
                Value = 600 - (i % 20) * 5,
                TimestampUtc = now.AddMinutes(-i)
            }));
            await db.SensorReadings.AddRangeAsync(readings, ct);

            await db.SaveChangesAsync(ct);
        }
    }
}


