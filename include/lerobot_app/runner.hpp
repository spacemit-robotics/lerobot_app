/*
 * Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef RUNNER_HPP
#define RUNNER_HPP

#include <string>
#include <vector>

namespace lerobot_app {

/**
 * @brief Result of invoking a task command.
 */
struct CommandResult {
    int exit_code = 0;
    std::string command;
};

/**
 * @brief Prepare runtime environment and dispatch LeRobot tasks.
 */
class Runner {
public:
    Runner();

    std::string app_dir() const;
    std::string repo_root() const;
    std::string venv_dir() const;
    std::string setup_script() const;
    std::string pick_cube_script() const;

    bool ensure_environment() const;
    CommandResult run_pick_cube(const std::vector<std::string>& extra_args = {}) const;

private:
    static std::string quote(const std::string& value);
    static int run_shell_command(const std::string& command);
};

}  // namespace lerobot_app

#endif  // RUNNER_HPP
