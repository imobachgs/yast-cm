require "cm/runners/base"
require "cheetah"

module Yast
  module CM
    module Runners
      # Runs Salt in order to configure the system
      class Salt < Base

      private

        # Try to apply system configuration in client mode
        #
        # The Salt runner does not care about retries and auth_time_outs as they
        # are set in the minion's configuration file.
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_client_mode
        def run_client_mode(stdout, stderr)
          with_retries(auth_attempts, auth_time_out) do
            run_cmd("salt-call", "--log-level", "debug", "state.highstate",
              stdout: stdout, stderr: stderr)
          end
        end

        # Try to apply system configuration in masterless mode
        #
        # @param stdout [IO] Standard output channel used by the configurator
        # @param stderr [IO] Standard error channel used by the configurator
        #
        # @return [Boolean] +true+ if run was successful; +false+ otherwise.
        #
        # @see Yast::CM::Runners::Base#run_masterless_mode
        def run_masterless_mode(stdout, stderr)
          with_retries(auth_attempts, auth_time_out) do
            run_cmd("salt-call", "--log-level", "debug", "--local",
              "--file-root=#{definitions_root}", "state.highstate",
              stdout: stdout, stderr: stderr)
          end
        end
      end
    end
  end
end
