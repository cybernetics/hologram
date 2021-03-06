require 'optparse'

module Hologram
  class CLI
    attr_reader :args

    def initialize(args)
      @args = args
    end

    def run
      return setup if args[0] == 'init'

      #support passing the config file with no command line flag
      config = args[0].nil? ? 'hologram_config.yml' : args[0]
      root = nil

      OptionParser.new do |opt|
        opt.on_tail('-h', '--help', 'Show this message.') { puts opt; exit }
        opt.on_tail('-v', '--version', 'Show version.') { puts "hologram #{Hologram::VERSION}"; exit }
        opt.on('-c', '--config FILE', 'Path to config file. Default: hologram_config.yml') { |config_file| config = config_file }
        opt.on('-r', '--root DIR', 'Path to use as root directory. Default: current directory') { |root_dir| root = root_dir }
        opt.parse!(args)
      end

      if !root.nil?
        Dir.chdir(root)
      else
        #Make it so that paths are relative to config file instead of
        #the pwd
        base_path = Pathname.new(config)
        config = base_path.realpath.to_s
        Dir.chdir(base_path.dirname)
      end
       config.nil? ? build : build(config)

    rescue Errno::ENOENT
      DisplayMessage.error("Could not load config file, try 'hologram init' to get started")
    end

    private

    def build(config = 'hologram_config.yml')
      builder = DocBuilder.from_yaml(config)
      DisplayMessage.error(builder.errors.first) if !builder.is_valid?
      builder.build
    rescue CommentLoadError, NoCategoryError => e
      DisplayMessage.error(e.message)
    end

    def setup
      DocBuilder.setup_dir
    rescue => e
      DisplayMessage.error("#{e}")
    end
  end
end
