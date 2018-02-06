require "optparse"
module ManageIQ
  module SOS
    class CLI
      def self.parse(argv)
        options = {:sort => :pid, :details => :details}

        OptionParser.new do |opt|
          opt.banner = "Usage: sos_report"
          opt.separator ""
          opt.separator "Summary of the status of the machine"
          opt.separator ""
          opt.separator "Options"
          opt.on("-h", "--help",         "Show this help")           { puts opt ; exit }
          opt.on("-r", "--raw",          "Show the raw report")      { options[:raw] = true }
          opt.parse!(argv)
        end
        options
      end

      def self.run(argv)
        ManageIQ::SOS::Report.new(parse(argv)).define_commands.run
      end
    end
  end
end

