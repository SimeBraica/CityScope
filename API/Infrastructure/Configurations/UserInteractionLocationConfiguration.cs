using Infrastructure.Configurations;
using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class UserInteractionLocationConfiguration : IEntityTypeConfiguration<UserInteractionLocation> {
        public void Configure(EntityTypeBuilder<UserInteractionLocation> builder) {

            builder.HasKey(c => c.Id);

        }

    }
}
