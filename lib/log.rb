unless defined? log

  def log(msg)
    puts "--> **#{msg}**"
  end


  def logg(msg)
    puts "--- #{msg}"
  end


  def loggg(msg)
    puts "---- #{msg}"
  end


  def error(msg)
    puts "[ERROR] #{msg}"
  end

end
