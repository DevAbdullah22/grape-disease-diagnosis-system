using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DOGD_API.Models
{
    public class TreatmentStep
    {
        [Key]
        public Guid Id { get; set; }

        public Guid TreatmentPlanId { get; set; }

        public int StepOrder { get; set; }    // 1,2,3,4
        public string PesticideName { get; set; }
        public string ChemicalGroup { get; set; }

        public string? PesticideImageUrl { get; set; }

        public string DosageInstructions { get; set; }
        public string MixQuantityAndType { get; set; }
        public string SafetyInfo { get; set; }
        public string? ImportantNotes { get; set; }


        [ForeignKey("TreatmentPlanId")]
        public TreatmentPlan TreatmentPlan { get; set; }
    }
}
