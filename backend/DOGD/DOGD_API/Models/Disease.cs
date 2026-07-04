namespace DOGD_API.Models
{
    public class Disease
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ImageUrl { get; set; }

        public TreatmentPlan TreatmentPlan { get; set; }

        public ICollection<ReferenceImage> ReferenceImages { get; set; } = new List<ReferenceImage>();


    }

}
