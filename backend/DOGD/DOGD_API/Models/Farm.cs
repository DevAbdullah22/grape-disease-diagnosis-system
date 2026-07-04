// DOGD_API/Models/Farm.cs
using System;

namespace DOGD_API.Models
{
    public class Farm
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }

        public User User { get; set; }
    }
}
