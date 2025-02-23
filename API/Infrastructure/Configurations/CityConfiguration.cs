using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class CityConfiguration : IEntityTypeConfiguration<City> {
        public void Configure(EntityTypeBuilder<City> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.Property(c => c.Longitude);

            builder.Property(c => c.Latitude);

            builder.HasMany(c => c.Users)
                .WithOne(c => c.City)
                .HasForeignKey(c => c.CityId);

            builder.HasMany(c => c.Locations)
              .WithOne(c => c.City)
              .HasForeignKey(c => c.CityId);
         
        }

    }
}
