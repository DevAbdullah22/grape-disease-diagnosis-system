using DOGD_API.Application.DTOs.FarmDtos;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FarmsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public FarmsController(AppDbContext db)
        {
            _db = db;
        }

        // GET /api/farms?userId={guid}
        [HttpGet("/api/farms")]
        public async Task<IActionResult> GetFarms([FromQuery] Guid? userId)
        {
            var q = _db.Farms.AsNoTracking().AsQueryable();
            if (userId.HasValue && userId != Guid.Empty)
                q = q.Where(f => f.UserId == userId.Value);

            var list = await q.Select(f => new
            {
                id = f.Id,
                userId = f.UserId,
                name = f.Name,
                latitude = f.Latitude,
                longitude = f.Longitude
            }).ToListAsync();

            return Ok(list);
        }

        // GET /api/farms/{id}
        [HttpGet("/api/farms/{id:guid}")]
        public async Task<IActionResult> GetById([FromRoute] Guid id)
        {
            var farm = await _db.Farms.AsNoTracking().FirstOrDefaultAsync(f => f.Id == id);
            if (farm == null) return NotFound();
            return Ok(farm);
        }

        // POST /api/farms
        [HttpPost("/api/farms")]
        public async Task<IActionResult> Create([FromBody] CreateFarmDto dto)
        {
            if (dto == null || dto.UserId == Guid.Empty)
                return BadRequest("Invalid payload");

            var farm = new Farm
            {
                Id = Guid.NewGuid(),
                UserId = dto.UserId,
                Name = dto.Name ?? string.Empty,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude
            };

            _db.Farms.Add(farm);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = farm.Id }, farm);
        }

        // DELETE /api/farms/{id}
        [HttpDelete("/api/farms/{id:guid}")]
        public async Task<IActionResult> Delete([FromRoute] Guid id)
        {
            var farm = await _db.Farms.FirstOrDefaultAsync(f => f.Id == id);
            if (farm == null) return NotFound();

            _db.Farms.Remove(farm);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
