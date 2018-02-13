module Adad
  class Generate

    # Initialize a number with its unit
    #
    # ==== Attributes
    # +value+:: value of the number
    # +epsilon+:: absolute uncertainty(-ies) of the value
    # +units+:: units and their powers, e.g. :kg, 1, :m, 1, :s, -2
    #
    # ==== Examples
    # > H = Adad.new 67.48, [0.98], :km, 1, :Mpc, -1, :s, -1
    # => #<Adad::Generate:...>
    def initialize(value, epsilon=nil, *units_and_powers)
      @A = { v: value, u: { L: [], M: [], T: [], Th: [], N: [] }, e: [0, 0]}

      unless epsilon.nil?
        case epsilon.length
        when 0
          @A[:e] = [0, 0]
        when 1
          @A[:e] = [epsilon[0], epsilon[0]]
        when 2
          @A[:e] = epsilon
        else
          raise ArgumentError, "Don't know how to handle uncertainties"
        end
      end

      units_and_powers.each_slice(2) do |unit, pow|
        prfx, symb = extract_prfx unit

        Dim.each do |dim|
          next unless U[dim].key? symb
          @A[:u][dim] << Adad::gen_unit(prfx, symb, pow)
        end

        DU[symb].each do |d,us|
          us.each do |u|
            @A[:u][d] << Adad::gen_unit(u[:prfx], u[:symb], u[:pow] * pow)
          end
        end if DU.key? symb
      end
    end


    # Returns the value of the number
    def value
      @A[:v]
    end

    def v
      self.value()
    end


    # Returns the unit of the number
    def unit
      unit = "["
      @A[:u].each do |_,us|
        us.each do |u|
          unit += " #{u[:prfx] unless u[:prfx] == :one}#{u[:symb]}"
          unit += "^#{u[:pow]}" unless u[:pow] == 1
        end
      end
      unit += " ]"
    end

    def u
      self.unit()
    end


    # Uncertainties
    def e
      @A[:e]
    end


    # Cloning
    def clone
      adad = Adad.new @A[:v]
      adad.instance_variable_get(:@A)[:u] = Marshal.load(Marshal.dump(@A[:u]))
      adad.instance_variable_get(:@A)[:e] = Marshal.load(Marshal.dump(@A[:e]))
      return adad
    end


    # Convert the unit of the number to a given unit
    def to(*units_and_powers)
      # TODO: Check if dimensions match

      adad, a = self._clone

      remove_units(a)

      units_and_powers.each_slice(2) do |unit, pow|
        prfx, symb = extract_prfx unit

        Dim.each do |dim|
          next unless U[dim].key? symb

          u = Adad::gen_unit(prfx, symb, pow)

          a[:v] /= conv_fact(u)
          a[:u][dim] << u
        end

        DU[symb].each do |d, us|
          us.each do |u|
            a[:v] /= conv_fact(u)
            a[:u][d] << Adad::gen_unit(u[:prfx], u[:symb], u[:pow] * pow)
          end
        end if DU.key? symb
      end

      return adad
    end


    # Simplify units by canceling similar dimensions (if present)
    def simplify!()
      Dim.each do |dim|
        next if @A[:u][dim].length <= 1

        sum_pows = @A[:u][dim].map { |u| u[:pow] }.reduce(:+)
        @A[:u][dim].each { |u| @A[:v] *= conv_fact(u) }

        return @A[:u][dim] = [] if sum_pows == 0

        def_u = U[dim][:default]
        @A[:u][dim] = [Adad::gen_unit(def_u[:prfx], def_u[:symb], sum_pows)]
        @A[:v] /= conv_fact(def_u)
      end

      return
    end


    def tot_pow(us)
      return us.map { |u| u[:pow] }.reduce(:+) || 0
    end


    def same_unit?(us)
      Dim.each { |d| return false unless tot_pow(@A[:u][d]) == tot_pow(us[d]) }
    end


    def +(m, mod=1)
      raise ArgumentError unless m.is_a? Adad::Generate

      adad, a = self._clone
      m_a = m.instance_variable_get(:@A)

      raise ArgumentError unless self.same_unit? m_a[:u]

      a[:v] += m_a[:v] * _to_SI(m_a[:u]) / _to_SI(@A[:u]) * mod

      return adad
    end


    def -(m)
      self.+(m, -1)
    end


    # Multiplying with an Adad instance or a scalar
    # TODO: using coerce to be able to run scalar * Adad
    def *(m, mod=1)
      new_adad = Adad::Generate.new 1
      new_A = new_adad.instance_variable_get(:@A)

      new_A[:u] = Marshal.load(Marshal.dump(@A[:u]))

      new_A[:e] = Marshal.load(Marshal.dump(@A[:e]))

      if m.is_a? (Numeric)
        new_A[:v] = @A[:v] * m**mod
        [0,1].each { |i| new_A[:e][i] *= m }
      elsif m.is_a? (Adad::Generate)
        m_A = m.instance_variable_get(:@A)
        [0,1].each { |i| new_A[:e][i] = m_A[:v] * new_A[:e][i] + new_A[:v] * m_A[:e][i] }

        new_A[:v] = @A[:v] * m_A[:v]**mod

        m_A[:u].each do |dim, m_us|
          m_us.each do |m_u|
            ix = new_A[:u][dim].find_index do |u|
              u[:prfx] == m_u[:prfx] and u[:symb] == m_u[:symb]
            end

            if ix
              new_A[:u][dim][ix][:pow] += m_u[:pow] * mod
              new_A[:u][dim].delete_at(ix) if new_A[:u][dim][ix][:pow] == 0
            else
              new_A[:u][dim] << Marshal.load(Marshal.dump(m_u.dup))
              new_A[:u][dim][-1][:pow] *= 1 * mod
            end
          end
        end
      end

      return new_adad
    end


    # Dividing by an Adad instance or a scalar
    def /(m)
      self.*(m, -1)
    end


    def **(m)
      # if m.is_a? (Adad::Generate)
      # TODO: check if the units are empty
      #   m = m.v
      # end

      new_adad = Adad::Generate.new(@A[:v]**m)
      new_A = new_adad.instance_variable_get(:@A)
      new_A[:u] = Marshal.load(Marshal.dump(@A[:u]))

      new_A[:u].each { |_, us| us.each { |u| u[:pow] *= m } }

      new_A[:e] = Marshal.load(Marshal.dump(@A[:e]))
      [0,1].each { |i| new_A[:e][i] *= m }

      return new_adad
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


    # Returns the SI conversion factor
    def _to_SI(units)
      units.map { |_,us| us.map { |u| conv_fact(u) } }.flatten.reduce :*
    end


    def _clone
      adad = self.clone
      return adad, adad.instance_variable_get(:@A)
    end


    def conv_fact(unit)

      d = nil
      Dim.each { |dim| d = dim if U[dim].key? unit[:symb] }
      raise ArgumentError, "Unknown unit: #{unit}" unless d

      (PRFX[unit[:prfx]] * U[d][unit[:symb]][:conv])**unit[:pow]
    end


    def remove_units(a)
      Dim.each do |dim|
        a[:u][dim].each { |u| a[:v] *= conv_fact(u) }
        a[:u][dim] = []
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
      g: { conv: 0.001 },
      Msun: { conv: 1.989e30 },
    },
    T: {
      default: gen_unit(:one, :s, 1),
      s: { conv: 1 },
      yr: { conv: 3.154e7 },
    },
    Th: {
      default: gen_unit(:one, :K, 1),
      K: { conv: 1 },
    },
    N: {
      default: gen_unit(:one, :mol, 1),
      mol: { conv: 1},
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
