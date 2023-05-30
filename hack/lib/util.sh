#!/usr/bin/env bash

# https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Alpha&text=KubeBB
GREETING='
          _____                    _____                    _____                    _____                    _____                    _____
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \
        /::\____\                /::\____\                /::\    \                /::\    \                /::\    \                /::\    \
       /:::/    /               /:::/    /               /::::\    \              /::::\    \              /::::\    \              /::::\    \
      /:::/    /               /:::/    /               /::::::\    \            /::::::\    \            /::::::\    \            /::::::\    \
     /:::/    /               /:::/    /               /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \
    /:::/____/               /:::/    /               /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \
   /::::\    \              /:::/    /               /::::\   \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \
  /::::::\____\________    /:::/    /      _____    /::::::\   \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \
 /:::/\:::::::::::\    \  /:::/____/      /\    \  /:::/\:::\   \:::\ ___\  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\ ___\  /:::/\:::\   \:::\ ___\
/:::/  |:::::::::::\____\|:::|    /      /::\____\/:::/__\:::\   \:::|    |/:::/__\:::\   \:::\____\/:::/__\:::\   \:::|    |/:::/__\:::\   \:::|    |
\::/   |::|~~~|~~~~~     |:::|____\     /:::/    /\:::\   \:::\  /:::|____|\:::\   \:::\   \::/    /\:::\   \:::\  /:::|____|\:::\   \:::\  /:::|____|
 \/____|::|   |           \:::\    \   /:::/    /  \:::\   \:::\/:::/    /  \:::\   \:::\   \/____/  \:::\   \:::\/:::/    /  \:::\   \:::\/:::/    /
       |::|   |            \:::\    \ /:::/    /    \:::\   \::::::/    /    \:::\   \:::\    \       \:::\   \::::::/    /    \:::\   \::::::/    /
       |::|   |             \:::\    /:::/    /      \:::\   \::::/    /      \:::\   \:::\____\       \:::\   \::::/    /      \:::\   \::::/    /
       |::|   |              \:::\__/:::/    /        \:::\  /:::/    /        \:::\   \::/    /        \:::\  /:::/    /        \:::\  /:::/    /
       |::|   |               \::::::::/    /          \:::\/:::/    /          \:::\   \/____/          \:::\/:::/    /          \:::\/:::/    /
       |::|   |                \::::::/    /            \::::::/    /            \:::\    \               \::::::/    /            \::::::/    /
       \::|   |                 \::::/    /              \::::/    /              \:::\____\               \::::/    /              \::::/    /
        \:|   |                  \::/____/                \::/____/                \::/    /                \::/____/                \::/____/
         \|___|                   ~~                       ~~                       \/____/                  ~~                       ~~
'
ROOT_PATH=$(git rev-parse --show-toplevel)

readonly PACKAGE_NAME="https://github.com/kubebb/core"
readonly OUTPUT_DIR="${ROOT_PATH}/_output"
readonly BUILD_GOPATH="${OUTPUT_DIR}/go"