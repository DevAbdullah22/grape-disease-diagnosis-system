using DOGD_API.Application.DTOs.LibraryCategoryDtos;
using DOGD_API.Application.Services.Library;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LibraryCategoryController : ControllerBase
    {
        private readonly ILibraryCategoryService _service;

        public LibraryCategoryController(ILibraryCategoryService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            return Ok(await _service.GetAllAsync());
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            var result = await _service.GetByIdAsync(id);
            if (result == null) return NotFound();
            return Ok(result);
        }

        // new endpoint: information needed before deleting
        [HttpGet("{id}/delete-info")]
        public async Task<IActionResult> GetDeleteInfo(Guid id)
        {
            var category = await _service.GetDeleteInfoAsync(id);
            if (category == null) return NotFound();
            return Ok(category);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] LibraryCategoryDto dto)
        {
            var result = await _service.CreateAsync(dto);
            return Ok(result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] LibraryCategoryDto dto)
        {
            var result = await _service.UpdateAsync(id, dto);
            if (result == null)
            {
                // could be not found or name conflict
                var existing = await _service.GetByIdAsync(id);
                if (existing == null) return NotFound();
                return Conflict(new { message = "Category name already in use." });
            }
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var deleted = await _service.DeleteAsync(id);
            if (!deleted)
            {
                var existing = await _service.GetByIdAsync(id);
                if (existing == null) return NotFound();
                // if deletion failed even though it exists, something else went wrong
                return BadRequest(new { message = "Failed to delete category." });
            }
            return Ok(true);
        }
    }
}
