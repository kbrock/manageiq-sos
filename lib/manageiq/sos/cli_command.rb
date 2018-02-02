module ManageIQ
  module SOS
    # a cli command that we call out to run
    class CLICommand
      attr_accessor :name, :cli

      def initialize(name, cli)
        @name = name
        @cli = cli
      end

      def raw
        @raw ||= exec_chomp_split(@cli)
      end

      def value(field = nil)
        raw
      end
   
      def clear
        @raw = nil
      end

      private
   
      def exec_chomp_split(cmd)
        %x{#{cmd}}.chomp.split("\n")
      end

      def self.create(format, *args)
        if format == :nv
          NvCLICommand.new(*args)
        else
          CLICommand.new(*args)
        end
      end
    end

    # Information from a CLI command that people want
    class SubCommand
      attr_accessor :command, :field
      def initialize(command, field)
        @command = command
        @field = field
      end

      def value(*_)
        @command.value(field)
      end
    end

    # A CLI Command that uses name values
    class NvCLICommand < CLICommand
      def value(field)
        field = /^ *#{Regexp.escape(field)}:/i if field.kind_of?(String)

        raw.grep(field).first.gsub(field,'').strip
      end
    end
  end
end
