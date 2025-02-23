using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities {
    public class UserInteractionLocation {
        
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; }
        
        public int LocationId { get; set; }
        public Location Location { get; set; }
        public int InteractionTypeId { get; set; }
        public InteractionType InteractionType { get; set; }
    }
}
