require './nombre'


class IdealGas
  # p = n k_B T = rho / (mu * m_H) * k_B T
  def initialize(p_Pa, rho_kg_m3, t_K, x=0.75, y=0.25, c_v=3.0/2.0)

    @p = p_Pa.is_a?(Nombre::Generate) ? p_Pa : Nombre.new(p_Pa, :Pa, 1)
    @rho = rho_kg_m3.is_a?(Nombre::Generate) ? rho_kg_m3 : Nombre.new(rho_kg_m3, :kg, 1, :m, -3)
    @T = t_K.is_a?(Nombre::Generate) ? t_K : Nombre.new(t_K, :K, 1)

    # Mean molecular mass
    @mu = Nombre.new(x + 4 * y)
    @m_H = Nombre.new 1.6737e-27, :kg, 1
    @m_He = Nombre.new 6.64648e-27, :kg, 1


    # Constants
    @k_B = Nombre.new 1.38064852e-23, :J, 1, :K, -1
    @R = Nombre.new 8.3144598, :J, 1, :K, -1, :mol, -1

    # Heat capacities
    @c_v = c_v.is_a?(Nombre::Generate) ? c_v : Nombre.new(c_v, :J, 1, :K, -1)
    @c_p = @c_v + 1
  end


  # Internal Energy
  def U()
    @c_v * @n * @R * @T
  end

  # Number of particles
  def N(volume_m3)
    self.n() * volume_m3
  end

  # Number density
  def n()
     @rho / @mu / @m_H
  end

  # Molar mass = R*T*rho / p
  def M()
    @R * @T * @rho / @p
  end

  def gamma()
    @c_p / @c_v
  end

  def c_sound()
  end
end
