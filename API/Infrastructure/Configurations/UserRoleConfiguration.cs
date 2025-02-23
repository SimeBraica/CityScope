using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {

    public class UserRoleConfiguration : IEntityTypeConfiguration<UserRole> {
        public void Configure(EntityTypeBuilder<UserRole> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.HasMany(c => c.Users)
                 .WithOne(c => c.UserRole)
                 .HasForeignKey(c => c.UserRoleId)
                 .IsRequired();
        }

    }

}
