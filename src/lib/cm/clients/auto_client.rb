require "yast"
require "installation/auto_client"
require "cm/provisioner"
require "cm/dialogs/running"

module Yast
  module CM
    # AutoClient implementation
    #
    # The real work is delegated to Provisioners.
    #
    # @see Yast::CM::Provisioner
    class AutoClient < ::Installation::AutoClient
      include Yast::I18n

      # zypp lock file
      ZYPP_PID = Pathname("/var/run/zypp.pid")
      # zypp lock backup file
      ZYPP_PID_BACKUP = ZYPP_PID.sub_ext(".sav")

      # Constructor
      def initialize
        Yast.import "Popup"
      end

      # Import AutoYaST configuration
      #
      # Additional provisioner-specific options can be specified. They will be passed
      # to the provisioner's constructor.
      #
      # @return profile [Hash] configuration from AutoYaST profile
      # @option profile [String] "type"     Provisioner to use ("salt", "puppet", etc.)
      # @option profile [String] "master"   Master server name
      # @option profile [String] "timeout"  Authentication timeout
      # @option profile [String] "attempts" Authentication retries
      def import(profile = {})
        config = {}
        profile.each_with_object(config) do |option, cfg|
          key = option[0].to_sym
          val = option[1]
          cfg[key] = val unless key == :type
        end

        type = profile["type"].nil? ? "salt" : profile["type"].downcase
        Provisioner.current = Provisioner.provisioner_for(type, config)
        true
      end

      # Return packages to install
      #
      # @see Provisioner#packages
      def packages
        Provisioner.current.packages
      end

      # Apply the configuration running the provisioner
      #
      # @see Provisioner#current
      def write
        dialog = Yast::CM::Dialogs::Running.new
        without_zypp_lock do
          dialog.run do |stdout, stderr|
            # Connect stdout and stderr with the dialog
            Provisioner.current.run(stdout, stderr)
          end
        end
        true
      end

      # Determines whether the profile data has been modified
      #
      # This method always returns `false` because no information from this
      # module is included in the cloned profile.
      #
      # @return [true]
      def modified?
        false
      end

      # Sets the profile as modified
      #
      # This method does not perform any modification because no information
      # from this module is included in the cloned profile.
      #
      # @return [true]
      def modified
        false
      end

      # Data to include in the cloned profile
      #
      # No information from this module in included in the cloned profile.
      #
      # @return [{}] Returns an empty Hash
      def export
        {}
      end

    private

      # Run a block without the zypp lock
      #
      # @param [Proc] Block to run
      def without_zypp_lock(&block)
        ::FileUtils.mv(ZYPP_PID, ZYPP_PID_BACKUP) if ZYPP_PID.exist?
        block.call
      ensure
        ::FileUtils.mv(ZYPP_PID_BACKUP, ZYPP_PID) if ZYPP_PID_BACKUP.exist?
      end
    end
  end
end
