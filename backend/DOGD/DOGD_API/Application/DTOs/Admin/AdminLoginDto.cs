
using System.ComponentModel.DataAnnotations;

namespace DOGD_API.Application.DTOs.Admin
{
    public class AdminLoginDto
    {
        [Required]
        public string Username { get; set; }

        [Required]
        public string Password { get; set; }
    }
}
