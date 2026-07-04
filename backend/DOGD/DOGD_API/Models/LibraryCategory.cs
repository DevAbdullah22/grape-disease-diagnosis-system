namespace DOGD_API.Models
{
    public class LibraryCategory
    {
        public Guid Id { get; set; }
        public string Name { get; set; }  // Diseases | Prevention | Recommendations

        public ICollection<LibraryItem> Items { get; set; }
    }

}
