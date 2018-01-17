require 'csv'

unless defined? EagleAPI
  module EagleAPI

    API = "http://galaxy-catalogue.dur.ac.uk:8080/Eagle"

    # Saving returned csv file on disk and loading it into an array
    # Params:
    # +dbname+:: Database name (simulation reference title)
    # +snapnum+:: Snapshot number
    # +passwd+:: API password
    # +path+::
    # +where+:: An array of conditions, e.g. ["SubGroupNumber = 0"]
    # +orderby+::
    def self.get(dbname, snapnum, passwd, where = nil, orderby = nil)

      path = "#{dbname}-#{snapnum}.txt"

      query = "SELECT *"
      query += " FROM #{dbname} as data"
      query += " WHERE data.SnapNum = #{snapnum}"
      where.each { |w| query += " and data.#{w}" } unless where.nil?
      query += " ORDER BY data.#{orderby}" unless orderby.nil?

      # TODO: Use NET::HTTP instead of wget!!
      unless File.exist?(path)
        system "wget --http-user ssarpas --http-passwd #{passwd} " \
               " \"#{API}?action=doQuery&SQL=#{query}\" -O #{path}"
      end

      keys, halos = {}, []

      CSV.foreach("#{path}") do |row|
        next if row.empty? or row[0] =~ /^#/

        if keys.empty?
          row.each_with_index{|k,i| keys.merge!(k.to_sym => i)}
          next
        end

        halos << row
      end

      return keys, halos
    end

  end
end
