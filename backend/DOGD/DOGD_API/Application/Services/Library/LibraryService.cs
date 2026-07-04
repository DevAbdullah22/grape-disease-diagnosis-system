using DOGD_API.Application.DTOs.LibraryCategoryDtos;
using DOGD_API.Application.DTOs.LibraryItemDtos;
using DOGD_API.Application.Services.Diagnosis;
using DOGD_API.Application.Services.Notifications_Service;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Library
{
    public class LibraryService : ILibraryService
    {
        private readonly AppDbContext _db;
        private readonly IImageUploadService _uploader;
        private readonly INotificationService _notificationService;

        public LibraryService(AppDbContext db, IImageUploadService uploader, INotificationService notificationService)
        {
            _db = db;
            _uploader = uploader;
            _notificationService = notificationService;
        }

        public async Task<List<LibraryCategoryDto>> GetAllCategoriesAsync()
        {
            return await _db.LibraryCategories
                .Select(c => new LibraryCategoryDto
                {
                    Id = c.Id,
                    Name = c.Name
                }).ToListAsync();
        }

        public async Task<List<LibraryItemDto>> GetItemsByCategoryAsync(Guid categoryId)
        {
            return await _db.LibraryItems
                .Where(i => i.CategoryId == categoryId)
                .Select(i => new LibraryItemDto
                {
                    Id = i.Id,
                    Title = i.Title,
                    Content = i.Content,
                    ShortDescription = i.ShortDescription,
                    ImageUrl = i.ImageUrl,
                    Sources = i.Sources,
                    CategoryName = i.Category != null ? i.Category.Name : null,
                    CreatedAt = i.CreatedAt,
                    UpdatedAt = i.UpdatedAt,
                    CategoryId = i.CategoryId
                }).ToListAsync();
        }

        public async Task<LibraryItemDto> GetItemByIdAsync(Guid id)
        {
            var item = await _db.LibraryItems
                .Include(i => i.Category)
                .FirstOrDefaultAsync(i => i.Id == id);
            if (item == null) return null;

            return new LibraryItemDto
            {
                Id = item.Id,
                Title = item.Title,
                Content = item.Content,
                ShortDescription = item.ShortDescription,
                ImageUrl = item.ImageUrl,
                Sources = item.Sources,
                CategoryName = item.Category != null ? item.Category.Name : null,
                CreatedAt = item.CreatedAt,
                UpdatedAt = item.UpdatedAt,
                CategoryId = item.CategoryId
            };
        }

        public async Task<LibraryItemDto> CreateItemAsync(CreateLibraryItemDto dto)
        {
            string? imageUrl = null;
            if (dto.Image != null)
            {
                imageUrl = await _uploader.UploadImageAsync(dto.Image);
            }

            var item = new LibraryItem
            {
                Id = Guid.NewGuid(),
                Title = dto.Title,
                Content = dto.Content,
                ShortDescription = dto.ShortDescription,
                ImageUrl = imageUrl,
                Sources = dto.Sources,
                CategoryId = dto.CategoryId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.LibraryItems.Add(item);
            await _db.SaveChangesAsync();

            // notify all subscribed users about the new library content
            try
            {
                var title = "محتوى جديد في المكتبة";
                var body = item.Title;
                Console.WriteLine($"[LibraryService] creating item {item.Id}, sending notifications");

                await _notificationService.SendToSubscribedUsersAsync("Library", title, body, item.Id);
            }
            catch (Exception ex)
            {
                _ = ex; // suppress unused-variable warning
            }

            // attach category name if available
            var category = await _db.LibraryCategories.FindAsync(item.CategoryId);
            var categoryName = category?.Name;

            return new LibraryItemDto
            {
                Id = item.Id,
                Title = item.Title,
                Content = item.Content,
                ShortDescription = item.ShortDescription,
                ImageUrl = item.ImageUrl,
                Sources = item.Sources,
                CategoryName = categoryName,
                CreatedAt = item.CreatedAt,
                UpdatedAt = item.UpdatedAt,
                CategoryId = item.CategoryId
            };
        }

        public async Task<LibraryItemDto> UpdateItemAsync(Guid id, CreateLibraryItemDto dto)
        {
            var item = await _db.LibraryItems.FindAsync(id);
            if (item == null) return null;

            item.Title = dto.Title;
            item.Content = dto.Content;
            item.ShortDescription = dto.ShortDescription;
            item.CategoryId = dto.CategoryId;
            item.Sources = dto.Sources;
            item.UpdatedAt = DateTime.UtcNow;

            if (dto.Image != null)
                item.ImageUrl = await _uploader.UploadImageAsync(dto.Image);

            await _db.SaveChangesAsync();

            return new LibraryItemDto
            {
                Id = item.Id,
                Title = item.Title,
                Content = item.Content,
                ShortDescription = item.ShortDescription,
                ImageUrl = item.ImageUrl,
                Sources = item.Sources,
                CategoryName = item.Category != null ? item.Category.Name : null,
                CreatedAt = item.CreatedAt,
                UpdatedAt = item.UpdatedAt,
                CategoryId = item.CategoryId
            };
        }

        public async Task<bool> DeleteItemAsync(Guid id)
        {
            var item = await _db.LibraryItems.FindAsync(id);
            if (item == null) return false;

            _db.LibraryItems.Remove(item);
            await _db.SaveChangesAsync();
            return true;
        }
    }
}
