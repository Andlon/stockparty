part of stock;

Random _rnd = new Random();

double rnorm({ double mean: 0.0, double std: 1.0 })
{
  // Use the Box-Muller transform to generate a standard
  // normally distributed number
  double U1 = _rnd.nextDouble();
  double U2 = _rnd.nextDouble();
  double R = sqrt(- 2.0 * log(U1));
  double theta = 2 * PI * U2;
  
  // This algorithm really generates two normally distributed values,
  // but for simplicity we discard the sin version.
  double Z = R * cos(theta);
  
  return (Z * std) + mean;
}

main() { }