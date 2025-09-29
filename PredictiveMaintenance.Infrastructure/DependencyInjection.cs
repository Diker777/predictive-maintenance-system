using Microsoft.Extensions.DependencyInjection;
using PredictiveMaintenance.Application.Abstractions;

namespace PredictiveMaintenance.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddScoped<IThresholdEvaluator, ThresholdEvaluator>();
        return services;
    }
}


