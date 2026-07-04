using DOGD_API.Application.DTOs.LibraryCategoryDtos;

namespace DOGD_API.Application.Services.Library
{
    public interface ILibraryCategoryService
    {
        Task<List<LibraryCategoryDto>> GetAllAsync();
        Task<LibraryCategoryDto> GetByIdAsync(Guid id);
        Task<LibraryCategoryDto> CreateAsync(LibraryCategoryDto dto);
        Task<LibraryCategoryDto> UpdateAsync(Guid id, LibraryCategoryDto dto);
        Task<bool> DeleteAsync(Guid id);

        // returns info needed by frontend before deletion
        Task<object> GetDeleteInfoAsync(Guid id);
    }
}
