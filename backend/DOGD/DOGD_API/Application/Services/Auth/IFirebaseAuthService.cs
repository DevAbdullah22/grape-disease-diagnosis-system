using System.Threading.Tasks;
using FirebaseAdmin.Auth;

namespace DOGD_API.Application.Services.Auth
{
    // واجهة لطبقة التحقق من توكن Firebase
    public interface IFirebaseAuthService
    {
        Task<FirebaseToken> VerifyIdTokenAsync(string idToken);
    }
}