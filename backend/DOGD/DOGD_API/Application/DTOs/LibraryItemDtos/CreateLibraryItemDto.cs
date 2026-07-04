namespace DOGD_API.Application.DTOs.LibraryItemDtos
{
    public class CreateLibraryItemDto
    {
        public string Title { get; set; }
        public string ShortDescription { get; set; }

        public string Content { get; set; }
        public IFormFile? Image { get; set; }
        public Guid CategoryId { get; set; }

        public string? Sources { get; set; }
    }

}