using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ThresholdsController : ControllerBase
{
    private readonly IAppDbContext _db;

    public ThresholdsController(IAppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ThresholdRule>>> Get([FromQuery] Guid? deviceId)
    {
        var q = _db.ThresholdRules.AsNoTracking();
        if (deviceId.HasValue) q = q.Where(r => r.DeviceId == deviceId);
        var list = await q.ToListAsync();
        return Ok(list);
    }

    [HttpPost]
    public async Task<ActionResult<ThresholdRule>> Create(ThresholdRule rule)
    {
        rule.Id = Guid.NewGuid();
        await _db.ThresholdRules.AddAsync(rule);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Get), new { deviceId = rule.DeviceId }, rule);
    }
}


