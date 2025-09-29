using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PredictiveMaintenance.Application.Abstractions;
using PredictiveMaintenance.Domain;

namespace PredictiveMaintenance.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DevicesController : ControllerBase
{
    private readonly IAppDbContext _db;

    public DevicesController(IAppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Device>>> GetAll()
    {
        var list = await _db.Devices.AsNoTracking().ToListAsync();
        return Ok(list);
    }

    [HttpPost]
    public async Task<ActionResult<Device>> Create(Device device)
    {
        device.Id = Guid.NewGuid();
        await _db.Devices.AddAsync(device);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = device.Id }, device);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Device>> GetById(Guid id)
    {
        var entity = await _db.Devices.FindAsync(id);
        return entity is null ? NotFound() : Ok(entity);
    }
}


