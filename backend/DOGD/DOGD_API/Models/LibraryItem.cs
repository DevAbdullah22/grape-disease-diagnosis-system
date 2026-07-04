namespace DOGD_API.Models
{
    public class LibraryItem
    {
        public Guid Id { get; set; }
        public Guid CategoryId { get; set; }
        public string Title { get; set; }
        public string Content { get; set; }
        public string? ShortDescription { get; set; }  
        public string ImageUrl { get; set; }
        public string? Sources { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public LibraryCategory Category { get; set; }
    }

}
