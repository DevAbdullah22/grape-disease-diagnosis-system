using System;

namespace DOGD_API.Application.DTOs.FarmDtos
{
    public class CreateFarmDto
    {
        public Guid UserId { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
