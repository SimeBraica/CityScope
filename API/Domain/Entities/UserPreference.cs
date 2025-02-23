using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities {
    public class UserPreference {
        public int Id { get; set; }
        public int Value { get; set; }

        public int UserId { get; set; }
        public User User { get; set; }

        public int PreferenceTypeId { get; set; }
        public PreferenceType PreferenceType { get; set; }
    
    }
}
