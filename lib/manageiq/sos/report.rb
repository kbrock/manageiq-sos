module ManageIQ
  module SOS
    class Report
      def initialize(options)
        @commands = {}
        @subcmds  = {}
      end

      # raw report for now
      def run
        [
          ## application
            :version,
            #:timedate,
              :date,
              :time_zone,
          ## processes
            #:lscpu,
              :num_cpus,
            #:top,
            #:ps,
            #:uptime,
          ## memory
            #:smem,
            #:vmstat,
          ## disk
           #:df,
           #:vmstat_disk,
          ## network
           #:ifconfig,
           #:netstat,
        ].each do |method|
          ret = send(method)
          ret = ret.join("\n") if ret.kind_of?(Array)

          puts "============", method, "============"
          puts "",ret,""
        end

        self
      end

      # define commands

      def cmd(format, name, cli = nil)
        @commands[name] = CLICommand.create(format, name, cli || name)
      end

      def subcmd(name, cmd, value)
        @subcmds[name] = SubCommand.new(@commands[cmd], value)
      end

      # implemented commands (this allows us to define a method instead of a command)

      def version
        @version ||= File.read("#{ENV["RAILS_ROOT"]}/VERSION").chomp
      end

      def method_missing(name, *args)
        if cmd = @commands[name.to_s]
          cmd.value(*args)
        elsif subcmd = @subcmds[name.to_s]
          subcmd.value(*args)
        else
          super
        end
      end

      def define_commands
        cmd    :nv,     "timedate",      "timedatectl"
        cmd    :nv,     "lscpu"
        ## todo:
        cmd    :top,    "top",           "top -c -b -n 1"
        cmd    :table,  "ps",            "ps aux"
        cmd    :uptime, "uptime"
        cmd    :table,  "smem",          "smem -s pid"
        cmd    :table,  "vmstat"         # memory version
        cmd    :table,  "df"
        cmd    :table,  "vmstat_disk",   "vmstat --disk"
        cmd    :table,  "ifconfig"
        cmd    :table,  "netstat",       "netstat --statistics --raw"
        cmd    :table,  "server_status", "cd #{ENV["RAILS_ROOT"]} ; rake evm:status_full"
        #cmd   :table,  "server_status", "rake evm:status", # version < "5.8"
        # "db_ping"

        subcmd "date", "timedate", "Local time"
        subcmd "time_zone", "timedate", "Time zone"
        subcmd "num_cpus", "lscpu", "CPU(s)"

        self
      end
    end
  end
end
