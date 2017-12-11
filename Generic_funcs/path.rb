unless defined? Path
  module Path
    @paths = {
      development: "~/development",
      local: "~/.local"
    }

    def self.dev
      return File.expand_path @paths[:development]
    end

    def self.local
      return File.expand_path @paths[:local]
    end

    def self.make_log(base)
      return "#{base}.log"
    end

    def self.make_config(base)
      return "#{base}.config"
    end

    def self.make_chombo(base)
      return "#{base}.chombo.hdf5"
    end
  end
end
