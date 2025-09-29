using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Infrastructure;

public class ThresholdEvaluator : IThresholdEvaluator
{
    private readonly IAppDbContext _db;

    public ThresholdEvaluator(IAppDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Alert>> EvaluateAsync(SensorReading reading, CancellationToken ct = default)
    {
        var rules = await _db.ThresholdRules
            .Where(r => r.DeviceId == reading.DeviceId && r.Metric == reading.Metric && r.Enabled)
            .ToListAsync(ct);

        var alerts = new List<Alert>();
        foreach (var rule in rules)
        {
            if (IsTriggered(rule, reading.Value))
            {
                alerts.Add(new Alert
                {
                    Id = Guid.NewGuid(),
                    DeviceId = reading.DeviceId,
                    Metric = reading.Metric,
                    Value = reading.Value,
                    Severity = rule.Severity,
                    Message = BuildMessage(rule, reading.Value),
                    CreatedUtc = DateTime.UtcNow,
                    Acknowledged = false
                });
            }
        }
        if (alerts.Count > 0)
        {
            await _db.Alerts.AddRangeAsync(alerts, ct);
            await _db.SaveChangesAsync(ct);
        }
        return alerts;
    }

    private static bool IsTriggered(ThresholdRule rule, double value)
    {
        return rule.Operator switch
        {
            ThresholdOperator.GreaterThan => value > (rule.MaxValue ?? double.MaxValue),
            ThresholdOperator.GreaterThanOrEqual => value >= (rule.MaxValue ?? double.MaxValue),
            ThresholdOperator.LessThan => value < (rule.MinValue ?? double.MinValue),
            ThresholdOperator.LessThanOrEqual => value <= (rule.MinValue ?? double.MinValue),
            ThresholdOperator.Between => value >= (rule.MinValue ?? double.MinValue) && value <= (rule.MaxValue ?? double.MaxValue),
            _ => false
        };
    }

    private static string BuildMessage(ThresholdRule rule, double value)
    {
        return rule.Operator switch
        {
            ThresholdOperator.GreaterThan => $"{rule.Metric} value {value} > {rule.MaxValue}",
            ThresholdOperator.GreaterThanOrEqual => $"{rule.Metric} value {value} >= {rule.MaxValue}",
            ThresholdOperator.LessThan => $"{rule.Metric} value {value} < {rule.MinValue}",
            ThresholdOperator.LessThanOrEqual => $"{rule.Metric} value {value} <= {rule.MinValue}",
            ThresholdOperator.Between => $"{rule.Metric} value {value} between {rule.MinValue} and {rule.MaxValue}",
            _ => $"{rule.Metric} value {value} triggered"
        };
    }
}


