using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities {
    public class Location {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Address { get; set; }
        public float Longitude { get; set; }
        public float Latitude { get; set; }
        public string Description { get; set; }
        public string MediaUrl { get; set; }
        public int LocationTypeId { get; set; }
        public LocationType LocationType { get; set; }
        
        public int CityId { get; set; }
        public City City { get; set; }

        public ICollection<UserInteractionLocation> UserInteractionLocations { get; set; }
    }
}
