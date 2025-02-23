using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class LocationConfiguration : IEntityTypeConfiguration<Location> {
        public void Configure(EntityTypeBuilder<Location> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.Property(c => c.Address)
                   .IsRequired();

            builder.Property(c => c.Longitude);

            builder.Property(c => c.Latitude);

            builder.Property(c => c.Description)
              .IsRequired();

            builder.Property(c => c.MediaUrl);

            builder.HasMany(c => c.UserInteractionLocations)
                 .WithOne(c => c.Location)
                 .HasForeignKey(c => c.LocationId);
        }

    }
}
