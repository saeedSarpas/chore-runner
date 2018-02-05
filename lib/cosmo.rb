require_relative './nombre.rb'

class Cosmo

  def initialize(ver=:planck15)
    cosmologies = {
      planck15: {
        Obh2: Nombre.new(0.02222, [0.00023]),
        Och2: Nombre.new(0.1199, [0.0022]),
        Om: Nombre.new(0.316, [0.014]),
        h: Nombre.new(0.6726),
        H0: Nombre.new(67.26, [0.98], :km, 1, :Mpc, -1, :s, -1),
        n_s: Nombre.new(0.9652, [0.0062]),
        tau: Nombre.new(0.078, [0.019]),
        sigma_8: Nombre.new(0.830, [0.015])
      }
    }

    @cosmo = cosmologies[ver]
  end

  def h
    @comso[:h]
  end

  def Ob
    @cosmo[:Obh2] / (@cosmo[:h]**2)
  end

  def Oc
    @cosmo[:Och2] / (@cosmo[:h]**2)
  end

  def Om
    @cosmo[:Om]
  end

  def H0
    @cosmo[:H0]
  end
end
