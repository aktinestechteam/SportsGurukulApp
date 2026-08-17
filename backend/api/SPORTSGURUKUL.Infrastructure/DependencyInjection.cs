using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Infrastructure.Email;
using SPORTSGURUKUL.Infrastructure.Persistence;
using SPORTSGURUKUL.Infrastructure.Persistence.Repositories;
using SPORTSGURUKUL.Infrastructure.Seeders;
using SPORTSGURUKUL.Infrastructure.Security;

namespace SPORTSGURUKUL.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<JwtOptions>(configuration.GetSection("Jwt"));
        services.Configure<EmailOptions>(configuration.GetSection("Email"));
        services.Configure<AppOptions>(configuration.GetSection("App"));

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<AppDbContext>());
        services.AddScoped<DbSeeder>();

        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IRoleRepository, RoleRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        services.AddScoped<IPasswordResetTokenRepository, PasswordResetTokenRepository>();
        services.AddScoped<IAcademyRepository, AcademyRepository>();
        services.AddScoped<ICoachRepository, CoachRepository>();
        services.AddScoped<IAthleteRepository, AthleteRepository>();
        services.AddScoped<ICoachAthleteRepository, CoachAthleteRepository>();

        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<ISecureTokenService, SecureTokenService>();
        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<ITokenPairService, TokenPairService>();
        services.AddScoped<IPublicUserIdGenerator, PublicUserIdGenerator>();
        services.AddScoped<ITemporaryPasswordGenerator, TemporaryPasswordGenerator>();

        return services;
    }
}
