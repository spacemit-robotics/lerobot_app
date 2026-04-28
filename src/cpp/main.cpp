/*
 * Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "lerobot_app/runner.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

constexpr int kFailureExitCode = 1;
constexpr char kPickCubeCommand[] = "tool-pick-cube";

void PrintUsage(const char* program) {
    std::cout << "Usage: " << program << " tool-pick-cube [-- <extra args...>]\n";
}

std::vector<std::string> CollectExtraArgs(int argc, char* argv[]) {
    std::vector<std::string> extra_args;
    for (int i = 2; i < argc; ++i) {
        if (std::string(argv[i]) == "--") {
            continue;
        }
        extra_args.emplace_back(argv[i]);
    }
    return extra_args;
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc < 2) {
        PrintUsage(argv[0]);
        return kFailureExitCode;
    }

    const std::string command = argv[1];
    if (command != kPickCubeCommand) {
        PrintUsage(argv[0]);
        return kFailureExitCode;
    }

    lerobot_app::Runner runner;
    if (!runner.ensure_environment()) {
        std::cerr << "[lerobot_app] failed to prepare environment\n";
        return kFailureExitCode;
    }

    const std::vector<std::string> extra_args = CollectExtraArgs(argc, argv);
    const auto result = runner.run_pick_cube(extra_args);
    std::cout << "[command] " << result.command << '\n';
    return result.exit_code;
}
