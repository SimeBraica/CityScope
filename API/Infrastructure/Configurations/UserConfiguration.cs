using Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class UserConfiguration : IEntityTypeConfiguration<User> {
        public void Configure(EntityTypeBuilder<User> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Username)
                    .IsRequired();

            builder.Property(c => c.Email)
                   .IsRequired();

            builder.Property(c => c.Password)
                  .IsRequired();

            builder.Property(c => c.Longitude);

            builder.Property(c => c.Latitude);

            builder.HasMany(c => c.UserInteractionLocations)
                 .WithOne(c => c.User)
                 .HasForeignKey(c => c.UserId);

            builder.HasMany(c => c.UserPreferences)
                 .WithOne(c => c.User)
                 .HasForeignKey(c => c.UserId);
        }

    }
}
