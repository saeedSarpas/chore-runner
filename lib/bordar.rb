require_relative './adad.rb'


module Bordar
  class Generate

    # Constructing a Border::Generate instance
    #
    # ==== Attributes
    # +length+:: length of the vector (Adad or scalar)
    # +direction+:: direction of the vector (var-length array of scalars)
    #
    # ==== Examples
    # > b = Bordar.new 67.48, [0.98], :km, 1, :Mpc, -1, :s, -1
    # => #<Adad::Generate:...>
    def initialize(length, direction)
      @B = {
        l: length.is_a?(Adad::Generate) ? length : Adad.new(length),
        d: direction.is_a?(Numeric) ? [direction] : direction
      }
    end


    # Length of the vector (Adad)
    def length
      @B[:l]
    end

    def l
      self.length()
    end


    # Direction of the vector (Array)
    def direction
      @B[:d]
    end

    def d
      self.direction()
    end


    # Multiplication of a vector with an Numeric or Adad
    def *(n)
      if n.is_a?(Numeric) or n.is_a?(Adad::Generate)
        new_bordar = Bordar::Generate.new(@B[:l] * n, [])

        new_B = new_bordar.instance_variable_get(:@B)
        new_B[:d] = Marshal.load(Marshal.dump(@B[:d]))

        return new_bordar
      else
        raise ArgumentError,
              'currently vector multiplication only accepts Adad or Numeric'
      end
    end
  end
end
