/*
 * Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "lerobot_app/runner.hpp"

#include <cstdlib>
#include <filesystem>
#include <sstream>

namespace fs = std::filesystem;

namespace lerobot_app {

namespace {

constexpr int kSuccessExitCode = 0;

std::string GetSourceDirectory() {
    return fs::path(__FILE__).parent_path().string();
}

}  // namespace

Runner::Runner() = default;

std::string Runner::app_dir() const {
    return fs::weakly_canonical(fs::path(GetSourceDirectory()) / "../..").string();
}

std::string Runner::repo_root() const {
    return fs::weakly_canonical(fs::path(app_dir()) / "../../..").string();
}

std::string Runner::venv_dir() const {
    return (fs::path(repo_root()) / "output" / "envs" / "lerobot_app").string();
}

std::string Runner::setup_script() const {
    return (fs::path(app_dir()) / "scripts" / "setup_env.sh").string();
}

std::string Runner::pick_cube_script() const {
    return (fs::path(app_dir()) / "scripts" / "pick_cube_record.sh").string();
}

bool Runner::ensure_environment() const {
    if (fs::exists(venv_dir())) {
        return true;
    }

    const std::string command = "bash " + quote(setup_script());
    return run_shell_command(command) == kSuccessExitCode;
}

CommandResult Runner::run_pick_cube(const std::vector<std::string>& extra_args) const {
    CommandResult result;

    std::ostringstream command;
    command << "bash " << quote(pick_cube_script());
    for (const auto& arg : extra_args) {
        command << ' ' << quote(arg);
    }

    result.command = command.str();
    result.exit_code = run_shell_command(result.command);
    return result;
}

std::string Runner::quote(const std::string& value) {
    std::string escaped = "'";
    for (char ch : value) {
        if (ch == '\'') {
            escaped += "'\\''";
        } else {
            escaped += ch;
        }
    }
    escaped += "'";
    return escaped;
}

int Runner::run_shell_command(const std::string& command) {
    return std::system(command.c_str());
}

}  // namespace lerobot_app
