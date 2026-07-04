using System;

namespace DOGD_API.Application.DTOs.DiseaseDtos
{
    public class UpdateDiseaseDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
    }
}
