unless defined? log_ext

  def log_ext(base)
    return "#{base}.log"
  end


  def config_ext(base)
    return "#{base}.config"
  end


  def chombo_ext(base)
    return "#{base}.chombo.hdf5"
  end
end
