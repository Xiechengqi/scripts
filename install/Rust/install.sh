#!/usr/bin/env bash

source $HOME/.cargo/env
cargo version &> /dev/null && echo "Rust has been installed" && cargo version && exit 0
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
