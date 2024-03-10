set dotenv-load := true

# Defining variables
FORK_BLOCK_NUMBER := "19400000"
# Comet whale account on ethereum mainnet
# FROM := "0x267ed5f71EE47D3E45Bb1569Aa37889a2d10f91e"
FROM := "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Commands
axiomlog:
    forge script AxiomLogScript \
        -f anvil

axiomlogb:
    forge script AxiomLogScript \
        -f anvil --broadcast

castlog:
    cast logs 0x8fb315489be5d4c2b40fabc3d9e39a788429abe814fe4e5a494405c7cfef6036 \
        -r anvil --from-block 19392974 --to-block 19392974

anvil:
    anvil -f $RPC_MAINNET --fork-block-number {{FORK_BLOCK_NUMBER}} --auto-impersonate

setup:
    forge script SetupBooScript \
        -f anvil --froms {{FROM}} --broadcast -vvvv

setup-mock:
    forge script SetupBooEventsScript \
        -f anvil --froms {{FROM}} --broadcast  

boo:
    forge script CallBooScript \
        -f anvil --froms {{FROM}} --broadcast

logs:
    cast logs 0x05a5d0ee0cd31fa17105f3377bc6e4a373e033600b3cf02ce30bffb01cd71b83 -r anvil \
        --from-block 19400000 --to-block 19400010