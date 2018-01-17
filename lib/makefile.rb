unless defined? Makefile

  # Generating Makefile
  class Makefile
    def initialize
      @make = {}
      @make[:define] = []
      @make[:var] = []
      @make[:rule] = []
      @make[:plain] = []
    end

    # it predefines name as macros, also set the name and their values globally
    def define(key, value)
      @make[:define] << { "-D#{key}" => value.to_s }
      @make[:var] << { key.to_s => value.to_s }
    end

    def set(key, value)
      if (var = @make[:var].find { |v| v.key? key.to_s })
        var[key.to_s] = value.to_s
      else
        @make[:var] << { key.to_s => value.to_s }
      end
    end

    def extend(key, value)
      var = @make[:var].find { |v| v.key? key.to_s }
      var[key.to_s] << " #{value}"
    end

    def rule(target, deps, *body)
      @make[:rule] << { target: target, deps: deps, body: body }
    end

    def plain(text)
      @make[:plain] << text
    end

    def write(path)
      File.open(path, 'w') do |f|
        f.write('DEFINES =')
        @make[:define].map { |d| f.write(" #{d.keys[0]}=#{d.values[0]}") }
        f.write("\n")

        @make[:var].map { |v| f.puts("#{v.keys[0]} = #{v.values[0]}") }

        @make[:plain].map { |p| f.puts(p) }

        @make[:rule].each do |r|
          f.write("#{r[:target]}: #{r[:deps]}\n")
          r[:body].map { |b| f.write("\t#{b}\n") }
        end
      end
    end
  end
end
