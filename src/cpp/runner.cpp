/*
 * Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "lerobot_app/runner.hpp"

#include <limits.h>
#include <stdlib.h>
#include <unistd.h>

#include <cstdlib>
#include <sstream>
#include <string>
#include <vector>

namespace {

std::string DirName(const std::string& path) {
    const std::string::size_type pos = path.find_last_of('/');
    if (pos == std::string::npos) {
        return ".";
    }
    if (pos == 0) {
        return "/";
    }
    return path.substr(0, pos);
}

std::string JoinPath(const std::string& base, const std::string& child) {
    if (base.empty() || base == ".") {
        return child;
    }
    if (base.back() == '/') {
        return base + child;
    }
    return base + "/" + child;
}

std::string CanonicalizePath(const std::string& path) {
    char resolved[PATH_MAX];
    if (realpath(path.c_str(), resolved) != nullptr) {
        return resolved;
    }
    return path;
}

bool PathExists(const std::string& path) {
    return access(path.c_str(), F_OK) == 0;
}

}  // namespace

namespace lerobot_app {

namespace {

constexpr int kSuccessExitCode = 0;

std::string GetSourceDirectory() {
    return DirName(__FILE__);
}

}  // namespace

Runner::Runner() = default;

std::string Runner::app_dir() const {
    return CanonicalizePath(JoinPath(GetSourceDirectory(), "../.."));
}

std::string Runner::repo_root() const {
    return CanonicalizePath(JoinPath(app_dir(), "../../.."));
}

std::string Runner::venv_dir() const {
    return JoinPath(JoinPath(JoinPath(repo_root(), "output"), "envs"), "lerobot_app");
}

std::string Runner::setup_script() const {
    return JoinPath(JoinPath(app_dir(), "scripts"), "setup_env.sh");
}

std::string Runner::pick_cube_script() const {
    return JoinPath(JoinPath(app_dir(), "scripts"), "pick_cube_record.sh");
}

bool Runner::ensure_environment() const {
    if (PathExists(venv_dir())) {
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
