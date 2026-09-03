using System;
using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Application.Videos.Interfaces;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Infrastructure.Email;
using SPORTSGURUKUL.Infrastructure.Persistence;
using SPORTSGURUKUL.Infrastructure.Persistence.Repositories;
using SPORTSGURUKUL.Infrastructure.Seeders;
using SPORTSGURUKUL.Infrastructure.Security;
using SPORTSGURUKUL.Infrastructure.Storage;

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
        services.Configure<AwsOptions>(configuration.GetSection("Aws"));

        // AWS S3 client built from the "Aws" config section, with environment
        // variable fallbacks so credentials are never required in source control.
        services.AddSingleton<IAmazonS3>(sp =>
        {
            var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<AwsOptions>>().Value;
            var accessKey = Environment.GetEnvironmentVariable("AWS_ACCESS_KEY_ID") ?? options.AccessKey;
            var secretKey = Environment.GetEnvironmentVariable("AWS_SECRET_ACCESS_KEY") ?? options.SecretKey;
            var regionName = Environment.GetEnvironmentVariable("AWS_REGION") ?? options.Region;

            var credentials = new BasicAWSCredentials(accessKey, secretKey);
            return new AmazonS3Client(credentials, RegionEndpoint.GetBySystemName(regionName));
        });

        // Allow switching to a local connection string via config flag or environment variable
        var useLocal = configuration.GetValue<bool>("UseLocalDb")
                       || Environment.GetEnvironmentVariable("USE_LOCAL_DB")?.ToLower() == "true";

        var defaultConn = configuration.GetConnectionString("DefaultConnection");
        var localConn = configuration.GetConnectionString("LocalConnection");
        var selectedConn = useLocal ? (localConn ?? defaultConn) : defaultConn;

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(selectedConn));

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
        services.AddScoped<IBatchRepository, BatchRepository>();
        services.AddScoped<IVideoRepository, VideoRepository>();

        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<ISecureTokenService, SecureTokenService>();
        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<IS3Service, S3Service>();
        services.AddScoped<ITokenPairService, TokenPairService>();
        services.AddScoped<IPublicUserIdGenerator, PublicUserIdGenerator>();
        services.AddScoped<ITemporaryPasswordGenerator, TemporaryPasswordGenerator>();

        return services;
    }
}
