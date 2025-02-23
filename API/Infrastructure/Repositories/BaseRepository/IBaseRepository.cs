using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Repositories.BaseRepository {
    public interface IBaseRepository<T> where T : class {

        Task<List<T>> Get();
        Task<T> GetById();
   }
}
