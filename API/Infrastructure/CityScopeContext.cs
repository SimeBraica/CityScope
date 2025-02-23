using Infrastructure.Configurations;
using Domain.Entities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure {
    public class CityScopeContext : DbContext {
        public CityScopeContext() { }
        public CityScopeContext(DbContextOptions dbContextOptions) : base(dbContextOptions) {
        }
        public DbSet<User> Users { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Location> Locations{ get; set; }
        public DbSet<LocationType> LocationTypes{ get; set; }
        public DbSet<InteractionType> InteractionTypes  { get; set; }
        public DbSet<UserInteractionLocation> UserInteractionsLocation { get; set; }
        public DbSet<UserPreference> UserPreferences { get; set; }
        public DbSet<PreferenceType> PreferenceTypes{ get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder) {
            modelBuilder.ApplyConfiguration(new UserConfiguration());
            modelBuilder.ApplyConfiguration(new UserRoleConfiguration());
            modelBuilder.ApplyConfiguration(new CityConfiguration());
            modelBuilder.ApplyConfiguration(new LocationConfiguration());
            modelBuilder.ApplyConfiguration(new LocationTypeConfiguration());
            modelBuilder.ApplyConfiguration(new InteractionTypeConfiguration());
            modelBuilder.ApplyConfiguration(new UserInteractionLocationConfiguration());
            modelBuilder.ApplyConfiguration(new PreferenceTypeConfiguration());
            modelBuilder.ApplyConfiguration(new UserPreferenceConfiguraion());
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
       => optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=CityScope;Username=postgres;Password=sime");
    }
}
