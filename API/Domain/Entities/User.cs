using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities {
    public class User {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public float Latitude { get; set; }
        public float Longitude { get; set; }

        public int UserRoleId { get; set; }
        public UserRole UserRole { get; set; }

        public int CityId { get; set; }
        public City City { get; set; }

        public ICollection<UserInteractionLocation> UserInteractionLocations { get; set; }
        public ICollection<UserPreference> UserPreferences { get; set; }
    }
}
