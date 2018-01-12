# Generating a FORTRAN namelist file
class FortranNamelist
  def initialize
    @blocks = {}
  end

  # Add a new block to @blocks
  # Params:
  # +name+:: Name of the block
  # +value+:: Hash containing variables of the namespace
  def add_block(name, value)
    @blocks[name.to_s.upcase] = value
  end

  def write(path, blocks = @blocks)
    File.open(path, 'w') do |f|
      blocks.each do |name, vars|
        f.wirte("&#{name.to_s}\n")
        vars.each { |k, v| f.write("#{k.to_s}=#{v}\n") }
        f.write("/\n\n")
      end
    end
  end
end
