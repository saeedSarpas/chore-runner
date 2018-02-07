module Nombre
  class Generate

    # Initialize a number with its unit
    #
    # ==== Attributes
    # +value+:: value of the number
    # +epsilon+:: absolute uncertainty(-ies) of the value
    # +units+:: units and their powers, e.g. :kg, 1, :m, 1, :s, -2
    #
    # ==== Examples
    # > H = Nombre.new 67.48, [0.98], :km, 1, :Mpc, -1, :s, -1
    # => #<Nombre::Generate:...>
    def initialize(value, epsilon=nil, *units_and_powers)
      @N = { v: value, u: { L: [], M: [], T: [], Th: [], N: [] }, e: [0, 0]}

      unless epsilon.nil?
        case epsilon.length
        when 0
          @N[:e] = [0, 0]
        when 1
          @N[:e] = [epsilon[0], epsilon[0]]
        when 2
          @N[:e] = epsilon
        else
          raise ArgumentError, "Don't know how to handle the uncertainties"
        end
      end

      units_and_powers.each_slice(2) do |unit, pow|
        prfx, symb = extract_prfx unit

        Dim.each do |dim|
          next unless U[dim].key? symb
          @N[:u][dim] << Nombre::gen_unit(prfx, symb, pow)
        end

        DU[symb].each do |d,us|
          us.each do |u|
            @N[:u][d] << Nombre::gen_unit(u[:prfx], u[:symb], u[:pow] * pow)
          end
        end if DU.key? symb
      end
    end


    # Returns the value of the number
    def v
      @N[:v]
    end


    # Returns the unit of the number
    def u
      unit = "["
      Dim.each do |dim|
        @N[:u][dim].each do |u|
          unit += " #{u[:prfx] if u[:prfx] != :one}#{u[:symb]}^#{u[:pow]}"
        end
      end
      unit += " ]"
    end


    # Uncertainties
    def e
      @N[:e]
    end


    # Convert the unit of the number to a given unit
    def to(*units_and_powers)
      new_nombre = Nombre::Generate.new @N[:v]
      new_N = new_nombre.instance_variable_get(:@N)
      new_N[:u] = Marshal.load(Marshal.dump(@N[:u]))

      remove_units(new_N)

      units_and_powers.each_slice(2) do |unit, pow|
        prfx, symb = extract_prfx unit

        Dim.each do |dim|
          next unless U[dim].key? symb

          u = Nombre::gen_unit(prfx, symb, pow)
          new_N[:v] /= conv_fact(u)
          new_N[:u][dim] << u
        end

        DU[symb].each do |dim, us|
          us.each do |u|
            new_N[:v] /= conv_fact(u)
            new_N[:u][dim] << u
          end
        end if DU.key? symb
      end

      return new_nombre
    end


    # Simplify the unit by canceling similar dimensions (if present)
    def simplify!()
      Dim.each do |dim|
        next if @N[:u][dim].length <= 1

        sum_pows = 0
        @N[:u][dim].each do |u|
          @N[:v] *= conv_fact(u)
          sum_pows += u[:pow]
        end

        if sum_pows == 0
          @N[:u][dim] = []
        else
          def_u = U[dim][:default]
          @N[:u][dim] = [def_u]
          @N[:u][dim][0][:pow] = sum_pows
          @N[:v] /= conv_fact(def_u)
        end
      end

      return
    end


    def +(m, mod=1)
      if m.is_a?(Numeric)
        new_nombre = Nombre::Generate.new @N[:v] + (m * mod)
        new_N = new_nombre.instance_variable_get(:@N)
        new_N[:u] = Marshal.load(Marshal.dump(@N[:u]))
        return new_nombre
      end

      _1st, _2nd = {}, {}
      m_N = m.instance_variable_get(:@N)

      [[@N, _1st], [m_N, _2nd]].each do |n, meas|
        n[:u].each do |dim, us|
          pow, factor = 0, 0
          us.each do |u|
            factor += PRFX[u[:prfx]] * U[dim][u[:symb]][:conv]
            pow += u[:pow]
          end
          meas[dim] = {f: factor, p: pow} unless pow == 0
        end
      end

      msg = "Arguments must have the same units"
      Dim.each do |d|
        raise ArgumentError, msg unless _1st.key?(d) == _2nd.key?(d)

        next unless _1st.key?(d)

        unless _1st[d][:f] == _2nd[d][:f] and _1st[d][:p] == _2nd[d][:p]
          raise ArgumentError, msg
        end
      end

      new_nombre = Nombre::Generate.new @N[:v]
      new_N = new_nombre.instance_variable_get(:@N)
      new_N[:v] += m_N[:v] * mod

      new_N[:u] = Marshal.load(Marshal.dump(@N[:u]))

      new_N[:e] = Marshal.load(Marshal.dump(@N[:e]))
      [0,1].each { |i| new_N[:e][i] += m_N[:e][i] }

      return new_nombre
    end


    def -(m)
      self.+(m, -1)
    end


    # Multiplying with a Nombre instance or a scalar
    # TODO: using coerce to be able to run scalar * Nombre
    def *(m, mod=1)
      new_nombre = Nombre::Generate.new 1
      new_N = new_nombre.instance_variable_get(:@N)

      new_N[:u] = Marshal.load(Marshal.dump(@N[:u]))

      new_N[:e] = Marshal.load(Marshal.dump(@N[:e]))

      if m.is_a? (Numeric)
        new_N[:v] = @N[:v] * m**mod
        [0,1].each { |i| new_N[:e][i] *= m }
      elsif m.is_a? (Nombre::Generate)
        m_N = m.instance_variable_get(:@N)
        [0,1].each { |i| new_N[:e][i] = m_N[:v] * new_N[:e][i] + new_N[:v] * m_N[:e][i] }

        new_N[:v] = @N[:v] * m_N[:v]**mod

        m_N[:u].each do |dim, m_us|
          m_us.each do |m_u|
            ix = new_N[:u][dim].find_index do |u|
              u[:prfx] == m_u[:prfx] and u[:symb] == m_u[:symb]
            end

            if ix
              new_N[:u][dim][ix][:pow] += m_u[:pow] * mod
              new_N[:u][dim].delete_at(ix) if new_N[:u][dim][ix][:pow] == 0
            else
              new_N[:u][dim] << Marshal.load(Marshal.dump(m_u.dup))
              new_N[:u][dim][-1][:pow] *= 1 * mod
            end
          end
        end
      end

      return new_nombre
    end


    # Dividing by a Nombre instance or a scalar
    def /(m)
      self.*(m, -1)
    end


    def **(m)
      # if m.is_a? (Nombre::Generate)
      # TODO: check if the units are empty
      #   m = m.v
      # end

      new_nombre = Nombre::Generate.new(@N[:v]**m)
      new_N = new_nombre.instance_variable_get(:@N)
      new_N[:u] = Marshal.load(Marshal.dump(@N[:u]))

      new_N[:u].each { |_, us| us.each { |u| u[:pow] *= m } }

      new_N[:e] = Marshal.load(Marshal.dump(@N[:e]))
      [0,1].each { |i| new_N[:e][i] *= m }

      return new_nombre
    end


    private
    def extract_prfx(unit)
      return :one, unit if DU.key? unit
      return :one, unit if unit.to_s.length == 1
      Dim.each { |dim| return :one, unit if U[dim].key? unit }

      PRFX.keys.each do |p|
        u = unit.to_s
        if u.start_with? p.to_s
          u[p.to_s] = ''
          return p, u.to_sym
        end
      end
    end


    def conv_fact(unit)
      d = nil
      Dim.each { |dim| d = dim if U[dim].key? unit[:symb] }
      raise ArgumentError, "Unknown unit: #{unit}" unless d

      (PRFX[unit[:prfx]] * U[d][unit[:symb]][:conv])**unit[:pow]
    end


    def remove_units(n)
      Dim.each do |dim|
        n[:u][dim].each { |u| n[:v] *= conv_fact(u) }
        n[:u][dim] = []
      end
    end
  end


  def self.new(value, epsilon=nil, *units)
    if epsilon.is_a?(Symbol)
      Generate.new value, nil, epsilon, *units
    else
      Generate.new value, epsilon, *units
    end
  end


  def self.gen_unit(prfx, symb, pow)
    { prfx: prfx, symb: symb, pow: pow}
  end


  U = { # Units
    L: {
      default: gen_unit(:one, :m, 1),
      m: { conv: 1 },
      pc: { conv: 3.086e16 },
    },
    M: {
      default: gen_unit(:k, :g, 1),
      g: { conv: 1 },
      Msun: { conv: 1.989e33 } # to gram
    },
    T: {
      default: gen_unit(:one, :s, 1),
      s: { conv: 1 },
      yr: { conv: 3.154e7 }
    },
    Th: {
      default: gen_unit(:one, :K, 1),
      K: { conv: 1 }
    },
    N: {
      default: gen_unit(:one, :mol, 1),
      mol: { conv: 1}
    }
  }

  Dim = U.keys # Dimension Symbols


  DU = { # Derived Units
    Hz: { T: [gen_unit(:one, :s, -1)] },
    J: {
      M: [gen_unit(:k, :g, 1)],
      L: [gen_unit(:one, :m, 2)],
      T: [gen_unit(:one, :s, -2)]
    },
    N: {
      M: [gen_unit(:k, :g, 1)],
      L: [gen_unit(:one, :m, 1)],
      T: [gen_unit(:one, :s, -2)]
    },
    Pa: {
      M: [gen_unit(:k, :g, 1)],
      L: [gen_unit(:one, :m, -1)],
      T: [gen_unit(:one, :s, -2)]
    },
    W: {
      M: [gen_unit(:k, :g, 1)],
      L: [gen_unit(:one, :m, 2)],
      T: [gen_unit(:one, :s, -3)]
    }
  }


  PRFX = { # Prefixes
    E: 1e18, P: 1e15, T: 1e12, G: 1e9, M: 1e6, k: 1e3, h: 1e2, one: 1,
    d: 1e-1, c: 1e-2, m: 1e-3, u: 1e-6, n: 1e-9, p: 1e-12, f: 1e-15, a: 1e-18
  }
end
