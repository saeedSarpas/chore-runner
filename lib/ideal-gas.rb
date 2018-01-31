import './nombre'

module IdealGas

  class Generate
    def initialize(p_Pa, n_mol, t_K, mu=1, m_p_kg=1.617e-27, c_v=3.0/2.0)

      @p = p_Pa.is_a? (Nombre::Generate) ? p_Pa : Nombre.new(p_Pa, :Pa, 1)
      @n = n_mol.is_a? (Nombre::Generate) ? n_mol : Nombre.new(n_mol, :mol, 1)
      @T = t_K.is_a? (Nombre::Generate) ? t_K : Nombre.new(t_K, :K, 1)
      @mu = mu.is_a? (Nombre::Generate) ? mu : Nombre.new(mu)
      @m_p = m_p_kg.is_a? (Nombre::Generate) ? m_p_kg : Nombre.new(m_p_kg, :kg, 1)

      @k_B = Nombre.new 1.381e-23, :J, 1, :K, -1
      @R = Nombre.new 8.314, :J, 1, :K, -1, :mol, -1

      @c_v = c_v.is_a? (Nombre::Generate) ? c_v : Nombre.new(c_v, :J, 1, :K, -1)
      @c_p = @c_v + 1
    end


    # Internal Energy
    def U()
      @c_v * @n * @R * @T
    end

    def N(n_mol)
      @n * @R / @k_B
    end

    def gamma()
      @c_p / @c_v
    end

    def c_sound()
    end
  end
end
