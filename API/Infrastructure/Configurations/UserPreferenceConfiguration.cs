using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class UserPreferenceConfiguraion : IEntityTypeConfiguration<UserPreference> {
        public void Configure(EntityTypeBuilder<UserPreference> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Value)
                    .IsRequired();
        }

    }
}
