# Generating RADAMESH parameter file
class RadameshParams
  def initialize
    @blocks = {
      # runtime: {},
      # species: {},
      # ic: {},
      # init_evol: {},
      # snapshot: {},
      # cosmology: {},
      # background: {},
      # sources: {},
      # ray_tracing: {},
      # output: {},
    }
  end

  def set_section(section, params)
    return unless params.is_a?(Hash)
    @blocks[section.to_sym] = params
  end

  def set(section, k, v)
    @blocks[section.to_sym][k.to_s] = v.to_s
  end

  def write(path, blocks=@blocks)
    File.open(path, 'w') do |f|
      blocks.each do |section, params|
        f.write("##{section}\n")
        params.each { |k, v| f.write("#{k.to_s} = #{v.to_s}\n") }
        f.write("\n")
      end
    end
  end
end
