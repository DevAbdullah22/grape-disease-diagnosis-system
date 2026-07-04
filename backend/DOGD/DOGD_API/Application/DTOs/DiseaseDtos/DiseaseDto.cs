using System;

namespace DOGD_API.Application.DTOs.DiseaseDtos
{
    public class DiseaseDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        // Primary image kept for compatibility but not required
        public string ImageUrl { get; set; } = string.Empty;

        // Reference images gallery
        public List<ReferenceImageDto> ReferenceImages { get; set; } = new List<ReferenceImageDto>();
    }
}
