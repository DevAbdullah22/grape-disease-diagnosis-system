using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Admin> Admins { get; set; }
        public DbSet<Disease> Diseases { get; set; }
        public DbSet<Diagnosis> Diagnoses { get; set; }
        public DbSet<ReferenceImage> ReferenceImages { get; set; }

        public DbSet<TreatmentPlan> TreatmentPlans { get; set; }
        public DbSet<TreatmentStep> TreatmentSteps { get; set; }

        public DbSet<TreatmentExecution> TreatmentExecutions { get; set; }
        public DbSet<LibraryCategory> LibraryCategories { get; set; }
        public DbSet<LibraryItem> LibraryItems { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationSubscription> NotificationSubscriptions { get; set; }
        // Weather alert entities
        public DbSet<DOGD_API.Models.Farm> Farms { get; set; }
        public DbSet<DOGD_API.Models.DiseaseWeatherRule> DiseaseWeatherRules { get; set; }



        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Diagnosis → Executions
            modelBuilder.Entity<Diagnosis>()
                .HasMany(d => d.Executions)
                .WithOne(e => e.Diagnosis)
                .HasForeignKey(e => e.DiagnosisId);

            // LibraryCategory → Items
            modelBuilder.Entity<LibraryCategory>()
                .HasMany(c => c.Items)
                .WithOne(i => i.Category)
                .HasForeignKey(i => i.CategoryId)
                // allow cascade delete so removing a category will remove its items
                .OnDelete(DeleteBehavior.Cascade);

            // Disease → ReferenceImages
            modelBuilder.Entity<Disease>()
                .HasMany(d => d.ReferenceImages)
                .WithOne(r => r.Disease)
                .HasForeignKey(r => r.DiseaseId);

            modelBuilder.Entity<TreatmentStep>()
    .HasIndex(s => new { s.TreatmentPlanId, s.StepOrder })
    .IsUnique();

        }
    }

}
