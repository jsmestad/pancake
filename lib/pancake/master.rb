module Pancake
  # A simple rack application
  OK_APP      = lambda{|env| Rack::Response.new("OK",         200,  {"Content-Type" => "text/plain"}).finish}
  MISSING_APP = lambda{|env| Rack::Response.new("NOT FOUND",  404,  {"Content-Type" => "text/plain"}).finish}

  extend Middleware

  class << self
    attr_accessor :root

    # Start Pancake.  This provides a full pancake stack to use inside a rack application
    #
    # @param        [Hash]    opts
    # @option opts  [String]  :root   The root of the pancake stack
    #
    # @example Starting a pancake stack
    #   Pancake.start(:root => "/path/to/root"){ MyApp # App to use}
    #
    # @api public
    # @author Daniel Neighman
    def start(opts, &block)
      raise "You must specify a root directory for pancake" unless opts[:root]
      self.root = opts[:root]

      # Build Pancake
      the_app = instance_eval(&block)
      Pancake::Middleware.build(the_app, middlewares)
    end

    # Provides the environment for the currently running pancake
    #
    # @return [String] The currently running environment
    # @api public
    # @author Daniel Neighman
    def env
      ENV['RACK_ENV'] ||= "development"
    end

    # A helper method to get the expanded directory name of a __FILE__
    #
    # @return [String] an expanded version of file
    # @api public
    # @author Daniel Neighman
    def get_root(file, *args)
      File.expand_path(File.join(File.dirname(file), *args))
    end

    # Labels that specify what kind of stack you're intending on loading.
    # This is a simliar concept to environments but it is in fact seperate conceptually.
    #
    # The reasoning is that you may want to use a particular stack type or types.
    # By using stack labels, you can define middleware to be active.
    #
    # @example
    #   Pancake.stack_labels == [:development, :demo]
    #
    #   # This would activate middleware marked with :development or :demo or the implicit :any label
    #
    # @return [Array<Symbol>]
    #   An array of labels to activate
    #   The default is [:production]
    # @see Pancake.stack_labels= to set the labels for this stack
    # @see Pancake::Middleware#stack to see how to specify middleware to be active for the given labels
    # @api public
    # @author Daniel Neighman
    def stack_labels
      return @stack_labels unless @stack_labels.nil? || @stack_labels.empty?
      self.stack_labels = [:production]
    end

    # Sets the stack labels to activate the associated middleware
    #
    # @param [Array<Symbol>, Symbol] An array of labels or a single label, specifying the middlewares to activate
    #
    # @example
    #   Pancake.stack_labels = [:demo, :production]
    #
    # @see Pancake.stack_labels
    # @see Pancake::Middleware#stack
    # @api public
    # @author Daniel Neighman
    def stack_labels=(*labels)
      @stack_labels = labels.flatten.compact
    end

    def handle_errors!(*args)
      @handle_errors = begin
                         if args.size > 1
                           args.flatten
                         else
                           args.first
                         end
                      end
    end

    def handle_errors?
      if @handle_errors.nil?
        !(Pancake.env == "development")
      else
        case @handle_errors
        when Array
          @handle_errors.include?(Pancake.env)
        when TrueClass, FalseClass
          @handle_errors
        when String
          Pancake.env == @handle_errors
        end
      end
    end

    def default_error_handling!
      @handle_errors = nil
    end

    def logger
      @logger ||= Pancake::Logger.new
    end

    def logger=(logr)
      @logger = logr
    end
  end # self
end # Pancake
