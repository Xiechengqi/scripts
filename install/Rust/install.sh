#!/usr/bin/env bash

source $HOME/.cargo/env
cargo version || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
