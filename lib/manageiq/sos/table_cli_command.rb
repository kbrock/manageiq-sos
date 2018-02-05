class TableCLICommand < CLICommand
  attr_accessor :skip
  attr_accessor :verbose

  def initialize(options = {})
    super
    @index = options[:index]
    @skip = options[:skip]
    @verbose = options[:verbose]
  end

  # not really relevant since it probably has a table of entries sorted by pid
  # maybe return a hash if looked up by pid?
  def value(index, field = nil)
    raw[index][field]
  end

  # raw is list of strings
  # table_data is [{}]
  def table_data
    @table_data ||= index_by(parse(raw), index)
  end

  private

  def index_by(arr, index)
    arr.each_with_object({}) do |row, hash|
      hash[row[index]] = row
    end
  end

  def non_space(c)
    c if c != ' '
  end

  def neighbors(data, i)
    hc = non_space(data[0][i])
    hp = non_space(data[0][i - 1]) if i != 0
    rc = non_space(data[1][i])
    rp = non_space(data[1][i - 1]) if i != 0
    [hc, hp, rc, rp]
  end

  def print_overview(header_row, data_row, headers = nil)
    print "#   "
    (0..([header_row.length, data_row.length].max)).each do |i|
      print i % 10 == 0 ? (i/10 % 10) : (i%10)
    end
    puts
    puts "    #{header_row}"
    puts "    #{data_row}"

    return unless headers

    headers.each_with_index do |header, i|
      txt = header[:end] == -1 ? "..." : "#{i % 10}" * (header[:end] - header[:start] + 1)
      puts "#{i}   #{" " * header[:start]}#{txt}"
    end
  end

  # print_data(data[skip..-1], headers) # TODO: skip..-1
  def print_data(data, headers)
    data[1..-1].each_with_index do |row, row_num|
      puts "%3d ====" % row_num
      headers.each do |header|
        puts "%3d %-20s %-40s" %[row_num, header[:name], row[header[:start]..header[:end]].strip]
      end
    end
  end

  # @param data [Array<String>] list of strings from the output of a command
  # @return 
  def parse(data)
    # TODO get into option parser
    # can't handle multi word headers (join with a _)
    header_row = data[skip].gsub(/Mounted ON/i, "mounted_on")
    data_row = data[skip+1]

    print_overview(header_row, data_row) if verbose

    headers = []
    header  = nil # current - could be headers.last
    (0..(header_row.length)).each do |i|
      hc, hp, rc, rp = neighbors(header_row, data_row, i)
      if hc && !hp # start
        header[:end] = (i - 2) if header && header[:mode] == :lj
        old_header = header
        headers << (header = {:name => hc})
        header[:start] = old_header ? (old_header[:end] + 2) : 0

        print  "%02ds #{" "*i}#{hc ? hc : '.'}" % i if verbose
        #print "    #{" "*i}#{rp ? 'X' : '.'}#{rc ? 'X' : '.'}" if verbose
        if !rc
          # NOTE: if old_header[:mode] == :lj, we're giving them priority (not perfect)
          header[:mode] = :rj
        elsif !rp
          header[:mode] = :lj
        elsif !old_header || old_header[:mode] == :rj
          header[:mode] = :rj
        else
          puts " ?1", "", "   #{" "*i}#{rp || '.'}#{rc || '.'}" if verbose
        end
        puts if verbose
      elsif !hc && hp #end
        print  "#{i}e #{" "*(header[:start])}#{header[:name]}#{hc || '.'}" if verbose
    #    print  "%02de #{" "*i}#{hc ? hc : '.'}" % i
        #print "    #{" "*i}#{rp ? 'X' : '.'}#{rc ? 'X' : '.'}"
        header[:mode] == :rj if !rp && header[:mode] != :lj
        header[:end] = i - 1 if header[:mode] == :rj
        puts " -- #{header.inspect}" if verbose
      elsif hc # doesn't work with spaces in headers. maybe no if?
        header[:name] << hc if hc
      end
    end
    headers.last[:end] = -1

    if verbose
      puts
      puts headers.map(&:inspect)
      puts
      print_overview(header_row, data_row, headers)
      puts
    end
  end
end
