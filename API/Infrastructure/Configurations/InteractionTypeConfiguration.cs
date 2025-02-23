using Domain.Entities;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Configurations {
    public class InteractionTypeConfiguration : IEntityTypeConfiguration<InteractionType> {
        public void Configure(EntityTypeBuilder<InteractionType> builder) {

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Name)
                    .IsRequired();

            builder.HasMany(c => c.UserInteractionsLocation)
                 .WithOne(c => c.InteractionType)
                 .HasForeignKey(c => c.InteractionTypeId);
        }

    }
}
