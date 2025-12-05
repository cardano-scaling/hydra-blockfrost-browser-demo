{ inputs, ... }:
{

  perSystem = { pkgs, ... }:
    {
      process-compose."alice" = {
        package = pkgs.process-compose;
        settings = {
          log_location = "devnet/logs/process-compose.log";
          log_level = "debug";

          processes = {
	    hydra-tui-alice = {
              working_dir = "./";
              command = pkgs.writeShellApplication {
                name = "alice-tui";
                text = ''
                  ${pkgs.hydra-tui}/bin/hydra-tui \
                    --connect 0.0.0.0:4001 \
                    --node-socket devnet/node.socket \
                    --testnet-magic 42 \
                    --cardano-signing-key devnet/credentials/alice-funds.sk
                '';
              };
              is_foreground = true;
              depends_on."hydra-node-alice".condition = "process_started";
            };

            hydra-node = {
              log_location = "./devnet/alice-logs.txt";
              command = pkgs.writeShellApplication {
                name = "hydra-node-alice";
                checkPhase = "";
                text = ''
                  set -a; [ -f .env ] && source .env; set +a
                  ${pkgs.hydra-node}/bin/hydra-node \
                    --node-id 1 \
                    --listen 127.0.0.1:5001 \
                    --api-port 4001 \
                    --monitoring-port 6001 \
                    --hydra-signing-key "${inputs.hydra}/demo/alice.sk" \
                    --cardano-signing-key "${inputs.hydra}/hydra-cluster/config/credentials/alice.sk" \
                    --hydra-scripts-tx-id ''$HYDRA_SCRIPTS_TX_ID \
                    --ledger-protocol-parameters "${inputs.hydra}/hydra-cluster/config/protocol-parameters.json" \
                    --blockfrost blockfrost-project.txt \
                    --persistence-dir devnet/persistence/alice \
                    --contestation-period 3s
                '';
              };
              working_dir = ".";
              ready_log_line = "NodeIsLeader";
            };
          };
        };
      };
    };
}
