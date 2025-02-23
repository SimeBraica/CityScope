using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class PreferenceTypeConfiguration : IEntityTypeConfiguration<PreferenceType> {
        public void Configure(EntityTypeBuilder<PreferenceType> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.HasMany(c => c.UserPreferences)
                 .WithOne(c => c.PreferenceType)
                 .HasForeignKey(c => c.PreferenceTypeId)
                 .IsRequired();
        }

    }
}
