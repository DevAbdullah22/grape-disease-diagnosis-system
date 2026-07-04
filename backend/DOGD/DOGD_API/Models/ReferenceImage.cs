using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DOGD_API.Models
{
    public class ReferenceImage
    {
        [Key]
        public int Id { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public Guid DiseaseId { get; set; }
        [ForeignKey("DiseaseId")]
        public Disease Disease { get; set; } = null!;
    }
}
