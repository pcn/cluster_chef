module ClusterChef

  #
  #
  module Discovery

    def announces(sys_name, aspects={})
      sys = System.new(sys_name, aspects)
      node[:discovery][system] = sys.to_hash
    end

    System = Struct.new(
      :name,
      :realm,
      :concerns,
      :version,
      #
      :stores,
      :daemons,
      :ports,
      :crons,
      :exports,
      #
      :dashboards,
      :description,
      :cookbook
      ) unless defined?(::ClusterChef::Discovery::System)
    System.class_eval do
      # include Chef::Mixin::CheckHelper
      # include Chef::Mixin::ParamsValidate
      # FORBIDDEN_IVARS = []
      # HIDDEN_IVARS    = []

      def initialize
      end

    end

    module StructAttr

      #
      # Returns a hash with each key set to its associated value.
      #
      # @example
      #    FooClass = Struct(:a, :b)
      #    foo = FooClass.new(100, 200)
      #    foo.to_hash # => { :a => 100, :b => 200 }
      #
      # @return [Hash] a new Hash instance, with each key set to its associated value.
      #
      def to_mash
        Mash.new.tap do |hsh|
          each_pair do |key, val|
            case
            when val.respond_to?(:to_mash) then hsh[key] = val.to_mash
            when val.respond_to?(:to_hash) then hsh[key] = val.to_hash
            else                                hsh[key] = val
            end
          end
        end
      end
      def to_hash() to_mash.to_hash ; end

      # barf.
      def store_into_node(node, a, b=nil)
        if b then
          node[a] ||= Mash.new
          node[a][b] = self.to_mash
        else
          node[a]    = self.to_mash
        end
      end

      module ClassMethods

        def discover()
        end

        def populate
        end

        def from_node(node, scope)
        end

        def dsl_attr(name, validation)
          name = name.to_sym
          define_method(name) do |arg|
            set_or_return(name, arg, validation)
          end
        end
      end
      def self.included(base) base.extend(ClassMethods) ; end
    end

    #
    # An *aspect* is an external property, commonly encountered across multiple
    # systems, that decoupled agents may wish to act on.
    #
    # For example, many systems have a Dashboard aspect -- phpMySQL, the hadoop
    # jobtracker web console, a one-pager generated by cluster_chef's
    # mini_dashboard recipe, or a purpose-built backend for your website. The
    # following independent concerns can act on such dashboard aspects:
    # * a dashboard dashboard creates a page linking to all of them
    # * your firewall grants access from internal machines and denies access on
    #   public interfaces
    # * the monitoring system checks that the port is open and listening
    #
    # Aspects are able to do the following:
    #
    # * Convert to and from a plain hash,
    #
    # * ...and thusly to and from plain node metadata attributes
    #
    # * discover its manifestations across all systems (on all or some
    #   machines): for example, all dashboards, or all open ports.
    #
    # * identify instances from a system's by-convention metadata. For
    #   example, given a chef server system at 10.29.63.45 with attributes
    #     `:chef_server => { :server_port => 4000, :dash_port => 4040 }`
    #   the PortAspect class would produce instances for 4000 and 4040, since by
    #   convention an attribute ending in `_port` means "I have a port aspect`;
    #   the DashboardAspect would recognize the `dash_port` attribute and
    #   produce an instance for `http://10.29.63.45:4040`.
    #
    # Note:
    #
    # * separate *identifiable conventions* from *concrete representation* of
    #   aspects. A system announces that it has a log aspect, and by convention
    #   declares a `:log_dir` attribute. At that point it is regularized into a
    #   LogAspect instance and stored in the `node[:aspects]` tree. External
    #   concerns should only inspect these concrete Aspects, and never go
    #   hunting for thins with a `:log_dir` attribute.
    #
    # * conventions can be messy, but aspects are perfectly uniform
    #
    Aspect = Struct.new(
      :name, :description, :long_desc
      ) unless defined?(::ClusterChef::Discovery::Aspect)
    Aspect.class_eval do
      include StructAttr
    end

    class AddressAspect < Struct.new(
        :public
        )
    end

    #
    # * scope[:log_dirs]
    # * scope[:log_dir]
    # * flavor: http, etc
    #
    class LogAspect < Struct.new(
        :dirs
        )
      ALLOWED_FLAVORS = [ :http, :log4j, :rails ]
      def from_node(scope, overrides)
      end
    end

    #
    # * attributes with a _dir or _dirs suffix
    #
    class StoreAspect < Struct.new(
        :name,
        :dirs,
        :flavor # log, conf, home, ...
        )
      ALLOWED_FLAVORS = [
        :home, :conf, :log, :tmp, :pid,
        :data, :lib, :journal, :cache,
      ]
    end

    #
    # * scope[:run_state]
    #
    # from the eponymous service resource,
    # * service.path
    # * service.pattern
    # * service.user
    # * service.group
    #
    class DaemonAspect < Struct.new(
        :name,
        :file, # daemon runner path
        :pattern, # pattern to detect process
        :run_state, # desired run state
        :user,
        :group
        )

    end

    class CronAspect
    end

    class AuthkeyAspect
    end

    #
    # Code assets (jars, compiled libs, etc) that another system may wish to
    # incorporate
    #
    class ExportAspect

    end

    # usage constraints -- ulimits, java heap size, thread count, etc
    class UsageLimitAspect
    end

    # deploy
    # package
    # account (user / group)

    class CookbookAspect < Struct.new(
        :name, :description, :long_desc,
        :deploys,
        :packages,
        :users,
        :groups,
        #
        :depends, :recommends,
        :supports,
        :attributes,
        :recipes,
        :resources,
        #
        :authors,
        :license,
        :version
        )
    end

    class PortAspect < Struct.new(
        :port_num,
        :is_public,
        :is_private,
        :port_state
        )
    end

    class DashboardAspect
      ALLOWED_FLAVORS = [ :http, :jmx ]
    end

    class VolumeAspect < Struct.new(
        :device, :mount_path, :fstype
        )
      ALLOWED_FLAVORS = [:persistent, :local, :fast, :bulk, :reserved, ]
    end


    # --------------------------------------------------------------------------
    #
    # Alternate syntax
    #

    # alias for #discovers
    #
    # @example
    #   can_haz(:redis) # => {
    #     :in_yr       => 'uploader_queue',             # alias for realm
    #     :mah_bukkit  => '/var/log/uploader',          # alias for logs
    #     :mah_sunbeam => '/usr/local/share/uploader',  # home dir
    #     :ceiling_cat => 'http://10.80.222.69:2345/',  # dashboards
    #     :o_rly       => ['mountable_volumes'],        # concerns
    #     :zomg        => ['redis_server'],             # daemons
    #     :btw         => %Q{Queue to process uploads}  # description
    #   }
    #
    #
    def can_haz(name, options={})
      system = discover(name, options)
      MAH_ASPECTZ_THEYR.each do |lol, real|
        system[lol] = system.delete(real) if aspects.has_key?(real)
      end
      system
    end

    # alias for #announces. As with #announces, all params besides name are
    # optional -- follow the conventions whereever possible. MAH_ASPECTZ_THEYR
    # has the full list of alternate aspect names.
    #
    # @example
    #   # announce a redis; everything according to convention except for the
    #   # custom log directory.
    #   i_haz_a(:redis, :mah_bukkit => '/var/log/uploader' )
    #
    def i_haz_a(system, aspects)
      MAH_ASPECTZ_THEYR.each do |lol, real|
        aspects[real] = aspects.delete(lol) if aspects.has_key?(lol)
      end
      announces(system, aspects)
    end

    # Alternate names for machine aspects. Only available through #i_haz_a and
    # #can_haz.
    #
    MAH_ASPECTZ_THEYR = {
      :in_yr => :realm, :mah_bukkit => :logs, :mah_sunbeam => :home,
      :ceiling_cat => :dashboards, :o_rly => :concerns, :zomg => :daemons,
      :btw => :description,
    }
  end
end