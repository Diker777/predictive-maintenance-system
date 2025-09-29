using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AlertsController : ControllerBase
{
    private readonly IAppDbContext _db;

    public AlertsController(IAppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Alert>>> Get([FromQuery] Guid? deviceId, [FromQuery] bool? acknowledged)
    {
        var q = _db.Alerts.AsNoTracking();
        if (deviceId.HasValue) q = q.Where(a => a.DeviceId == deviceId);
        if (acknowledged.HasValue) q = q.Where(a => a.Acknowledged == acknowledged);
        var list = await q.OrderByDescending(a => a.CreatedUtc).Take(500).ToListAsync();
        return Ok(list);
    }

    [HttpPost("ack/{id}")]
    public async Task<ActionResult> Ack(Guid id)
    {
        var alert = await _db.Alerts.FirstOrDefaultAsync(a => a.Id == id);
        if (alert is null) return NotFound();
        alert.Acknowledged = true;
        await _db.SaveChangesAsync();
        return NoContent();
    }
}


