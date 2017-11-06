unless defined? paCage

  def paCage
    return "paCage has been defined"
  end

  module PaCage

    # Cloning paCages
    # Params:
    # +dir+:: path to the directory that paCages will be cloned there (use ~ instead of $HOME)
    # +names+:: an array of the name of paCages
    def self.clone(dir, names)
      expanded_dir = File.expand_path("#{dir}")

      for name in names
        if Dir.exist?("#{expanded_dir}/#{name}")
          command = "cd #{expanded_dir}/#{name}"
          command += " && git pull origin \"$(git_current_branch)\""
          command += " && git submodule update --init"
        else
          command = "mkdir -p #{expanded_dir}"
          command += " && cd #{expanded_dir}"
          command += " && git clone git@github.com:paCage/#{name}.git"
          command += " && cd #{name}"
          command += " && git submodule update --init"
        end

        system command
      end
    end


    # Installing paCages (this method install the paCages into ~/.local directory)
    # Params:
    # +dir+:: path to the directory containing the paCages
    # +names+:: an array of the name of paCages
    def self.compile(dir, names)
      expanded_dir = File.expand_path("#{dir}")

      for name in names
        system "cd #{expanded_dir}/#{name} && make install"
      end
    end

    # Clone and installing paCages
    def self.cc(dir, names)
      self.clone(dir, names)
      self.compile(dir, names)
    end

  end
end
