using SPORTSGURUKUL.Application.Coaches.Interfaces;

namespace SPORTSGURUKUL.Infrastructure.Security;

public class TemporaryPasswordGenerator : ITemporaryPasswordGenerator
{
    private const string DefaultPassword = "Gurukul@123";

    public string Generate()
    {
        return DefaultPassword;
    }
}
