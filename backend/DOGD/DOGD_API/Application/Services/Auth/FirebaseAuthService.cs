using FirebaseAdmin.Auth;

namespace DOGD_API.Application.Services.Auth
{
    public class FirebaseAuthService : IFirebaseAuthService
    {
        // هذه الدالة تفحص صحة التوكن
        public async Task<FirebaseToken> VerifyIdTokenAsync(string idToken)
        {
            try
            {
                // FirebaseAdmin يتحقق من صحة التوكن ويرجع بيانات المستخدم
                return await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(idToken);
            }
            catch (Exception ex)
            {
                // نرمي خطأ واضح حتى نعرف لماذا فشل التحقق
                throw new UnauthorizedAccessException("Invalid Firebase ID token", ex);
            }
        }
    }
}