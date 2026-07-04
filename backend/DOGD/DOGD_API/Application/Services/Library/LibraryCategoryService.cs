using DOGD_API.Application.DTOs.LibraryCategoryDtos;
using DOGD_API.Data;
using DOGD_API.Models;
using Microsoft.EntityFrameworkCore;

namespace DOGD_API.Application.Services.Library
{
    public class LibraryCategoryService : ILibraryCategoryService
    {
        private readonly AppDbContext _db;

        public LibraryCategoryService(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<LibraryCategoryDto>> GetAllAsync()
        {
            return await _db.LibraryCategories
                .Select(c => new LibraryCategoryDto
                {
                    Id = c.Id,
                    Name = c.Name
                }).ToListAsync();
        }

        public async Task<LibraryCategoryDto> GetByIdAsync(Guid id)
        {
            var category = await _db.LibraryCategories.FindAsync(id);
            if (category == null) return null;

            return new LibraryCategoryDto
            {
                Id = category.Id,
                Name = category.Name,
            };
        }

        public async Task<LibraryCategoryDto> CreateAsync(LibraryCategoryDto dto)
        {
            var category = new LibraryCategory
            {
                Id = Guid.NewGuid(),
                Name = dto.Name,
            };

            _db.LibraryCategories.Add(category);
            await _db.SaveChangesAsync();

            return new LibraryCategoryDto
            {
                Id = category.Id,
                Name = category.Name,
            };
        }

        public async Task<LibraryCategoryDto> UpdateAsync(Guid id, LibraryCategoryDto dto)
        {
            var category = await _db.LibraryCategories.FindAsync(id);
            if (category == null) return null;

            // prevent duplicate names across other categories
            bool nameTaken = await _db.LibraryCategories
                .AnyAsync(c => c.Name == dto.Name && c.Id != id);
            if (nameTaken)
            {
                // returning null lets controller handle as conflict/not found
                return null;
            }

            category.Name = dto.Name;

            await _db.SaveChangesAsync();

            return new LibraryCategoryDto
            {
                Id = category.Id,
                Name = category.Name,
            };
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var category = await _db.LibraryCategories.FindAsync(id);
            if (category == null) return false;

            _db.LibraryCategories.Remove(category);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<object> GetDeleteInfoAsync(Guid id)
        {
            var category = await _db.LibraryCategories
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (category == null) return null;

            return new
            {
                categoryId = category.Id,
                categoryName = category.Name,
                itemsCount = category.Items.Count
            };
        }
    }
}
