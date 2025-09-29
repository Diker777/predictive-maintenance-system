using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Api.Hubs;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReadingsController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly IThresholdEvaluator _evaluator;
    private readonly IHubContext<AlertsHub> _hubContext;

    public ReadingsController(IAppDbContext db, IThresholdEvaluator evaluator, IHubContext<AlertsHub> hubContext)
    {
        _db = db;
        _evaluator = evaluator;
        _hubContext = hubContext;
    }

    [HttpPost]
    public async Task<ActionResult> Ingest(SensorReading reading, CancellationToken ct)
    {
        reading.Id = Guid.NewGuid();
        if (reading.TimestampUtc == default)
            reading.TimestampUtc = DateTime.UtcNow;

        await _db.SensorReadings.AddAsync(reading, ct);
        await _db.SaveChangesAsync(ct);

        var alerts = await _evaluator.EvaluateAsync(reading, ct);
        if (alerts.Count > 0)
        {
            await _hubContext.Clients.All.SendAsync("alerts", alerts, ct);
        }

        return Accepted(new { reading.Id, Alerts = alerts.Count });
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SensorReading>>> Query([FromQuery] Guid deviceId, [FromQuery] MetricType? metric, [FromQuery] DateTime? fromUtc, [FromQuery] DateTime? toUtc)
    {
        var q = _db.SensorReadings.AsNoTracking().Where(r => r.DeviceId == deviceId);
        if (metric.HasValue) q = q.Where(r => r.Metric == metric);
        if (fromUtc.HasValue) q = q.Where(r => r.TimestampUtc >= fromUtc);
        if (toUtc.HasValue) q = q.Where(r => r.TimestampUtc <= toUtc);

        var list = await q.OrderByDescending(r => r.TimestampUtc).Take(1000).ToListAsync();
        return Ok(list);
    }
}


