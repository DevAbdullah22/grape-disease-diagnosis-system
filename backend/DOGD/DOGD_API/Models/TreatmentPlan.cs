using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DOGD_API.Models
{
    public class TreatmentPlan
    {
        [Key]
        public Guid Id { get; set; }

        public Guid DiseaseId { get; set; }

        public string Name { get; set; }

        // global interval days between each step
        public int DoseIntervalDays { get; set; }

        public ICollection<TreatmentStep> Steps { get; set; }

        [ForeignKey("DiseaseId")]
        public Disease Disease { get; set; }
    }
}
