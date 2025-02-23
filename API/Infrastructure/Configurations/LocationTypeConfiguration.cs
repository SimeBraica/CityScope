using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class LocationTypeConfiguration : IEntityTypeConfiguration<LocationType> {
        public void Configure(EntityTypeBuilder<LocationType> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.HasMany(c => c.Locations)
                 .WithOne(c => c.LocationType)
                 .HasForeignKey(c => c.LocationTypeId)
                 .IsRequired();
        }

    }
}
