using DOGD_API.Application.DTOs.LibraryItemDtos;
using DOGD_API.Application.Services.Library;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LibraryController : ControllerBase
    {
        private readonly ILibraryService _service;

        public LibraryController(ILibraryService service)
        {
            _service = service;
        }

      

        [HttpGet("category/{categoryId}/items")]
        public async Task<IActionResult> GetItems(Guid categoryId)
        {
            var items = await _service.GetItemsByCategoryAsync(categoryId);
            return Ok(items);
        }

        [HttpGet("item/{id}")]
        public async Task<IActionResult> GetItem(Guid id)
        {
            var item = await _service.GetItemByIdAsync(id);
            if (item == null) return NotFound();
            return Ok(item);
        }

        [HttpPost("item")]
        public async Task<IActionResult> CreateItem([FromForm] CreateLibraryItemDto dto)
        {
            var item = await _service.CreateItemAsync(dto);
            return Ok(item);
        }

        [HttpPut("item/{id}")]
        public async Task<IActionResult> UpdateItem(Guid id, [FromForm] CreateLibraryItemDto dto)
        {
            var item = await _service.UpdateItemAsync(id, dto);
            if (item == null) return NotFound();
            return Ok(item);
        }

        [HttpDelete("item/{id}")]
        public async Task<IActionResult> DeleteItem(Guid id)
        {
            var deleted = await _service.DeleteItemAsync(id);
            if (!deleted) return NotFound();
            return Ok(true);
        }
    }

}
