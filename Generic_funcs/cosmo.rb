unless defined? Cosmo

  class Cosmo

    def initialize(ver)
      parameters = {
        planck13: {
          hubble: 0.6777
        }
      }

      @params = parameters[ver]
    end

    def hubble
      return @params[:hubble]
    end
  end
end
