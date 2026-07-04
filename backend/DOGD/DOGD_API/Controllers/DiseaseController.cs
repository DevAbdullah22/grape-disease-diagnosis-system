using DOGD_API.Data;
using DOGD_API.Application.DTOs;
using DOGD_API.Application.Services.Diagnosis;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DOGD_API.Application.DTOs.DiseaseDtos;

namespace DOGD_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DiseaseController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly Application.Services.Disease.IDiseaseService _service;
        private readonly IImageUploadService _imageUpload;

        public DiseaseController(AppDbContext db, Application.Services.Disease.IDiseaseService service, IImageUploadService imageUpload)
        {
            _db = db;
            _service = service;
            _imageUpload = imageUpload;
        }

        [HttpGet("{id}/reference-images")]
        public async Task<ActionResult<List<ReferenceImageDto>>> GetReferenceImages(Guid id)
        {
            var images = await _db.ReferenceImages
                .Where(r => r.DiseaseId == id)
                .Select(r => new ReferenceImageDto
                {
                    Id = r.Id,
                    ImageUrl = r.ImageUrl
                })
                .ToListAsync();

            // make image URLs absolute so clients can load them directly
            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            foreach (var img in images)
            {
                if (!string.IsNullOrWhiteSpace(img.ImageUrl) && img.ImageUrl.StartsWith("/"))
                    img.ImageUrl = baseUrl + img.ImageUrl;
            }

            return Ok(images);
        }

        [HttpPost("{id}/reference-images")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<List<ReferenceImageDto>>> AddReferenceImages(Guid id, [FromForm] List<IFormFile> files)
        {
            if (files == null || files.Count == 0)
                return BadRequest("No files provided.");

            try
            {
                var added = await _service.AddReferenceImagesAsync(id, files);
                return Ok(added);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpDelete("{id}/reference-images/{imageId}")]
        public async Task<IActionResult> DeleteReferenceImage(Guid id, int imageId)
        {
            try
            {
                await _service.DeleteReferenceImageAsync(id, imageId);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpGet]
        public async Task<ActionResult<List<DiseaseDto>>> GetAll()
        {
            var list = await _service.GetAllAsync();
            return Ok(list);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<DiseaseDto>> Get(Guid id)
        {
            var d = await _service.GetByIdAsync(id);
            if (d == null) return NotFound();
            return Ok(d);
        }

        [HttpPost]
        public async Task<ActionResult<DiseaseDto>> Create([FromBody] CreateDiseaseDto dto)
        {
            var created = await _service.CreateAsync(dto);
            return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<DiseaseDto>> CreateForm([FromForm] CreateDiseaseDto dto, IFormFile? imageFile)
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest("Field 'name' is required.");

            // If the client used a different form field name for the file (eg. "image")
            // try to fallback to the first uploaded file so the API is more forgiving.
            if (imageFile == null && Request.HasFormContentType && Request.Form.Files.Count > 0)
            {
                imageFile = Request.Form.Files.First();
            }

            var created = await _service.CreateWithFileAsync(dto, imageFile);

            // If any additional files were uploaded (e.g. reference images), add them
            if (Request.HasFormContentType && Request.Form.Files.Count > 0)
            {
                var files = Request.Form.Files.Where(f => f != imageFile).ToList();
                if (files.Count > 0)
                {
                    await _service.AddReferenceImagesAsync(created.Id, files.Select(f => (IFormFile)f).ToList());
                    // reload created with reference images
                    created = await _service.GetByIdAsync(created.Id) ?? created;
                }
            }

            return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<DiseaseDto>> Update(Guid id, [FromBody] UpdateDiseaseDto dto)
        {
            if (id != dto.Id) return BadRequest("Id mismatch");
            try
            {
                var updated = await _service.UpdateAsync(dto);
                return Ok(updated);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpPut("{id}")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<DiseaseDto>> UpdateForm(Guid id, [FromForm] UpdateDiseaseDto dto, IFormFile? imageFile)
        {
            // allow missing dto.Id in form by using route id
            if (dto.Id == Guid.Empty) dto.Id = id;
            if (id != dto.Id) return BadRequest("Id mismatch");

            var existing = await _db.Diseases.FindAsync(id);
            if (existing == null) return NotFound();


            // determine which form keys were provided
            var form = Request.HasFormContentType ? Request.Form : null;
            bool hasName = form != null && form.ContainsKey("name");
            bool hasDescription = form != null && form.ContainsKey("description");
            bool hasImageUrl = form != null && form.ContainsKey("imageUrl");

            // fallback to any uploaded file if binding didn't populate imageFile
            if (imageFile == null && Request.HasFormContentType && Request.Form.Files.Count > 0)
            {
                imageFile = Request.Form.Files.First();
            }

            try
            {
                var updated = await _service.UpdateWithFileAsync(id, dto, imageFile, hasName, hasDescription, hasImageUrl);

                // handle any additional uploaded reference images
                if (Request.HasFormContentType && Request.Form.Files.Count > 0)
                {
                    var files = Request.Form.Files.Where(f => f != imageFile).ToList();
                    if (files.Count > 0)
                    {
                        await _service.AddReferenceImagesAsync(updated.Id, files.Select(f => (IFormFile)f).ToList());
                        updated = await _service.GetByIdAsync(updated.Id) ?? updated;
                    }
                }

                return Ok(updated);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _service.DeleteAsync(id);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }
    }
}
