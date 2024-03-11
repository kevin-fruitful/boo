set dotenv-load := true

# Defining variables
FORK_BLOCK_NUMBER := "19400000"
# Comet whale account on ethereum mainnet
# FROM := "0x267ed5f71EE47D3E45Bb1569Aa37889a2d10f91e"
FROM := "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Start anvil fork mainnet
anvil:
    anvil -f $RPC_MAINNET --fork-block-number {{FORK_BLOCK_NUMBER}} --auto-impersonate

# Setup contracts and state on the fork. This is necessary to get logging.
setup:
    forge script SetupBooScript \
        -f anvil --froms {{FROM}} --broadcast

# Setup tx with event sigs expected by the circuit
setup-mock:
    forge script SetupBooEventsScript \
        -f anvil --froms {{FROM}} --broadcast  

# Call boo() on the fork
boo:
    forge script CallBooScript \
        -f anvil --froms {{FROM}} --broadcast 

# Get logs of the event Boo(...) from a given block range
logs:
    #!/usr/bin/env zsh
    set -euxo pipefail
    END_BLOCK=$(({{FORK_BLOCK_NUMBER}} + 10))
    cast logs 0x05a5d0ee0cd31fa17105f3377bc6e4a373e033600b3cf02ce30bffb01cd71b83 -r anvil \
        --from-block {{FORK_BLOCK_NUMBER}} --to-block $END_BLOCK