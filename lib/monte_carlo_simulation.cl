#pragma OPENCL EXTENSION cl_khr_fp64 : enable

double random_uniform()
{
  return (double)rand() / (double)RAND_MAX;
}

double random_normal(double mu, double sigma)
{
  const double epsilon = 1.0e-6;
  const double two_pi = 2.0 * 3.14159265358979323846;

  double z0, z1;
  double u1, u2;

  do {
    u1 = random_uniform();
    u2 = random_uniform();
  } while (u1 <= epsilon);

  z0 = sqrt(-2.0 * log(u1)) * cos(two_pi * u2);
  z1 = sqrt(-2.0 * log(u1)) * sin(two_pi * u2);

  return z0 * sigma + mu;
}

__kernel void monte_carlo_simulation(double last_closing_price, double drift, double sigma, int number_of_days, __global double *results)
{
  int gid = get_global_id(0);
  double price = last_closing_price;

  for (int i = 0; i < number_of_days; i++) {
    double random_factor = exp(drift + sigma * random_normal(0.0, 1.0));
    price *= random_factor;
  }

  results[gid] = price;
}
