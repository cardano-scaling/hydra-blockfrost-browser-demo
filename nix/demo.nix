_:
{
  perSystem = { pkgs, ... }:
    let
      networkName = "preview";
      networkMagic = "2";
      peers = [ "noon" ];
    in
    {
      process-compose."rpi" = {
        package = pkgs.process-compose;
        settings = {
          log_location = "run/logs/process-compose.log";
          log_level = "debug";
          processes = {
            hydra-tui-alice = {
              working_dir = "./";
              command = pkgs.writeShellApplication {
                name = "tui";
                text = ''
                  ${pkgs.hydra-tui}/bin/hydra-tui \
                    --connect 0.0.0.0:4001 \
                    --blockfrost blockfrost-project.txt \
                    --cardano-signing-key ../credentials/funds.sk
                '';
              };
              is_foreground = true;
              depends_on."hydra-node".condition = "process_started";
            };


            hydra-node = {
              availability.restart = "on_failure";
              log_location = "rpi-logs.txt";
              working_dir = "./run";
              command = pkgs.writeShellApplication {
                name = "hydra-node-rpi";
                text =
                  let
                    peerArgs =
                      let
                        dir = "../peers";
                        f = name: pkgs.lib.strings.concatStringsSep " "
                          [
                            "--peer \"$(cat ${dir}/${name}/peer)\""
                            "--hydra-verification-key \"${dir}/${name}/hydra.vk\""
                            "--cardano-verification-key \"${dir}/${name}/fuel.vk\""
                          ];
                      in
                      pkgs.lib.strings.concatMapStringsSep " " f peers;
                  in
                  ''
                    ${pkgs.hydra-node}/bin/hydra-node \
                      --node-id rpi \
                      --listen 127.0.0.1:5001 \
                      --api-port 4001 \
                      --monitoring-port 6001 \
                      --hydra-signing-key ../../credentials/hydra.sk \
                      --cardano-signing-key ../../credentials/fuel.sk \
                      --ledger-protocol-parameters ../peers/protocol-parameters.json \
                      --blockfrost ../blockfrost-project.txt \
                      --hydra-scripts-tx-id "3c275192a7b5ff199f2f3182f508e10f7e1da74a50c4c673ce0588b8c621ed45,6f8a4b6404d4fdd0254507e95392fee6a983843eb168f9091192cbec2b99f83d,60d61b2f10897bf687de440a0a8b348a57b1fc3786b7b8b1379a65ace1de199a" \
                      --persistence-dir persistence \
                      --contestation-period 300s \
                      --deposit-period 300s \
                      --persistence-rotate-after 10000 \
                      ${peerArgs}
                  '';
              };
            };
          };
        };
      };
    };
}
