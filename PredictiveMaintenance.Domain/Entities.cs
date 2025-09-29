namespace PredictiveMaintenance.Domain;

public enum MetricType
{
    CylinderStrokeTime = 1,
    ShaftTorque = 2,
    Speed = 3
}

public class Device
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public ICollection<SensorReading> Readings { get; set; } = new List<SensorReading>();
    public ICollection<ThresholdRule> ThresholdRules { get; set; } = new List<ThresholdRule>();
}

public class SensorReading
{
    public Guid Id { get; set; }
    public Guid DeviceId { get; set; }
    public Device? Device { get; set; }
    public MetricType Metric { get; set; }
    public double Value { get; set; }
    public DateTime TimestampUtc { get; set; }
}

public enum ThresholdOperator
{
    GreaterThan = 1,
    GreaterThanOrEqual = 2,
    LessThan = 3,
    LessThanOrEqual = 4,
    Between = 5
}

public class ThresholdRule
{
    public Guid Id { get; set; }
    public Guid DeviceId { get; set; }
    public Device? Device { get; set; }
    public MetricType Metric { get; set; }
    public ThresholdOperator Operator { get; set; }
    public double? MinValue { get; set; }
    public double? MaxValue { get; set; }
    public bool Enabled { get; set; } = true;
    public int Severity { get; set; } = 1; // 1-5
}

public class Alert
{
    public Guid Id { get; set; }
    public Guid DeviceId { get; set; }
    public Device? Device { get; set; }
    public MetricType Metric { get; set; }
    public double Value { get; set; }
    public string Message { get; set; } = string.Empty;
    public int Severity { get; set; }
    public DateTime CreatedUtc { get; set; }
    public bool Acknowledged { get; set; }
}


