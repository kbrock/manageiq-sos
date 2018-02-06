#!/usr/bin/env ruby

ENV["RAILS_ROOT"] = [
  ENV["RAILS_ROOT"], "#{ENV["HOME"]}/src/manageiq", "/var/www/miq/vmdb"
].detect { |p| p && File.exists?(p) }

# only needed if we use our classes
# require "#{ENV['RAILS_ROOT']}/config/environment"
require "optparse"
require "zlib"


# wrapper for the commands
class SOSReport
  class CLICommand
    attr_accessor :name, :cli

    def initialize(name, cli)
      @name = name
      @cli = cli
    end

    def raw
      @raw ||= exec_chomp_split(@cli)
    end

    def value(*_)
      raw
    end
 
    private
 
    def exec_chomp_split(cmd)
      %x{#{cmd}}.chomp.split("\n")
    end

    def self.create(format, *args)
      case format
      when :nv
        NvCLICommand.new(*args)
      #when :table
      #  TableCLICommand.new(*args)
      else
        CLICommand.new(*args)
      end
    end
  end

  # A Command that extracts from another command
  class SubCommand
    attr_accessor :command, :field
    def initialize(command, field)
      @command = command
      @field = field
    end

    def value(*_) ; command.value(field) ; end
  end

  # A CLI Command that uses name values
  class NvCLICommand < CLICommand
    def value(field)
      field = /^ *#{Regexp.escape(field)}:/i if field.kind_of?(String)
      raw.grep(field).first.gsub(field,'').strip
    end
  end
end

class SOSReport
  def initialize(options)
    @commands = {}
    @subcmds  = {}
    @raw     = [] # raw reports
    @published = [] # polished reports

    @options = options
  end

  # dsl

  def cmd(format, name, cli = nil)
    @commands[name] = CLICommand.create(format, name, cli || name)
    raw(name)
  end

  def subcmd(name, cmd, value)
    @subcmds[name] = SubCommand.new(@commands[cmd], value)
    publish(name)
  end

  def raw(*args)
    @raw += args.map(&:to_s)
  end

  def publish(*args)
    @published += args.map(&:to_s)
  end

  def method_missing(name, *args)
    if (cmd = (@commands[name.to_s] || @subcmds[name.to_s]))
      cmd.value(*args)
    else
      super
    end
  end

  # raw report for now
  def run
    (@options[:raw] ? @raw : @published).each do |method|
      ret = send(method)
      ret = ret.join("\n") if ret.kind_of?(Array)

      puts "============", method, "============"
      puts "",ret,""
    end
  end

  # Application Verion

  def version
    @version ||= File.read("#{ENV["RAILS_ROOT"]}/VERSION").chomp
  end
end

options = {}

OptionParser.new do |opt|
  opt.banner = "Usage: sos_report.rb"
  opt.separator ""
  opt.separator "Summary of the status of the machine"
  opt.separator ""
  opt.separator "Options"
  opt.on("-h", "--help", "Show this help") { puts opt ; exit }
  opt.on("--raw", "Raw report output") { |v| options[:raw] = true }
  opt.parse!
end

report = SOSReport.new(options)

# define commands
report.instance_eval do
  cmd    :raw,    "version",       "cat #{ENV["RAILS_ROOT"]}/VERSION"
  cmd    :nv,     "timedate",      "timedatectl"
  cmd    :nv,     "lscpu"                         # /proc/cpuinfo
  ## todo:
  cmd    :top,    "top",           "top -c -b -n 1"
  cmd    :table,  "ps",            "ps aux"
  cmd    :raw,    "uptime"
  cmd    :table,  "smem",          "smem -s pid"
  cmd    :table,  "vmstat"         # memory version
  cmd    :table,  "df"
  cmd    :table,  "vmstat_disk",   "vmstat --disk"
  cmd    :table,  "ifconfig"
  cmd    :table,  "netstat",       "netstat --statistics --raw"
  cmd    :table,  "server_status", "cd #{ENV["RAILS_ROOT"]} ; rake evm:status_full"
  #cmd   :table,  "server_status", "cd #{ENV["RAILS_ROOT"]} ; rake evm:status", # version < "5.8"
  # "db_ping"
  cmd    :yaml,   "config", "cd #{ENV["RAILS_ROOT"]} ; rails r 'puts YAML.dump(MiqServer.my_server.get_config.config)'"
  # subcmd "date", "timedate", "Local time"      # date
  # subcmd "time_zone", "timedate", "Time zone"
  # subcmd "num_cpus", "lscpu", "CPU(s)"

  publish "version", "uptime"
  # "db_ping"
# # Server config:
# c&U status ? what is this
# Zone

# # worker config:
# roles enabled
# c&u / refresh enabled?
# Per worker (count, memory threshold)

# MiqQueue status
# count of requests by type
# 
end

report.run
