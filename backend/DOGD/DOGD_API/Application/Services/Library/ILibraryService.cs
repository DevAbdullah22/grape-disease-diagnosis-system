using DOGD_API.Application.DTOs.LibraryCategoryDtos;
using DOGD_API.Application.DTOs.LibraryItemDtos;

namespace DOGD_API.Application.Services.Library
{
    public interface ILibraryService
    {
        Task<List<LibraryCategoryDto>> GetAllCategoriesAsync();
        Task<List<LibraryItemDto>> GetItemsByCategoryAsync(Guid categoryId);
        Task<LibraryItemDto> GetItemByIdAsync(Guid id);
        Task<LibraryItemDto> CreateItemAsync(CreateLibraryItemDto dto);
        Task<LibraryItemDto> UpdateItemAsync(Guid id, CreateLibraryItemDto dto);
        Task<bool> DeleteItemAsync(Guid id);
    }

}
