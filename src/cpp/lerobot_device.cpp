/*
 * Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <iostream>
#include <memory>
#include <string>

#include "lerobot_app/runner.hpp"
#include "mlink.h"

namespace {

constexpr int kSuccessExitCode = 0;
constexpr int kFailureExitCode = 1;
constexpr char kDefaultTransport[] = "unix";
constexpr char kDefaultServerName[] = "lerobot";
constexpr char kPickCubeToolName[] = "pick_cube";
constexpr char kPickCubeToolDescription[] = "Run the LeRobot pick-cube task";

struct ServerDeleter {
    void operator()(mlink_server_t* server) const {
        if (server) {
            mlink_server_destroy(server);
        }
    }
};

struct ToolDeleter {
    void operator()(mlink_tool_t* tool) const {
        if (tool) {
            mlink_tool_destroy(tool);
        }
    }
};

struct PropertyListDeleter {
    void operator()(mlink_property_list_t* props) const {
        if (props) {
            mlink_property_list_destroy(props);
        }
    }
};

struct DeviceContext {
    lerobot_app::Runner runner;
};

mlink_return_value PickCubeCallback(const mlink_property_list_t* props, void* user_ctx) {
    (void)props;
    auto* ctx = static_cast<DeviceContext*>(user_ctx);
    if (!ctx) {
        return mlink_return_string("missing device context");
    }

    if (!ctx->runner.ensure_environment()) {
        return mlink_return_string("failed to prepare lerobot environment");
    }

    const auto result = ctx->runner.run_pick_cube();
    if (result.exit_code != 0) {
        return mlink_return_string("pick_cube command failed");
    }

    return mlink_return_string("pick_cube finished");
}

bool RegisterPickCubeTool(mlink_server_t* server, DeviceContext* ctx) {
    std::unique_ptr<mlink_property_list_t, PropertyListDeleter> props(mlink_property_list_create());
    if (!props) {
        std::cerr << "Failed to create property list for pick_cube\n";
        return false;
    }

    std::unique_ptr<mlink_tool_t, ToolDeleter> tool(
        mlink_tool_create(
            kPickCubeToolName,
            kPickCubeToolDescription,
            props.get(),
            PickCubeCallback,
            ctx,
            false));

    if (!tool) {
        std::cerr << "Failed to create pick_cube tool\n";
        return false;
    }

    if (!mlink_server_add_tool(server, tool.get())) {
        std::cerr << "Failed to register pick_cube tool\n";
        return false;
    }

    tool.release();
    return true;
}

bool ResolveTransport(const std::string& transport_name, transport_type* type) {
    if (transport_name == "tcp") {
        *type = TRANSPORT_TYPE_TCP;
        return true;
    }

    if (transport_name == "unix") {
        *type = TRANSPORT_TYPE_UNIX;
        return true;
    }

    return false;
}

void PrintUsage(const char* program) {
    std::cout << "Usage: " << program << " [tcp|unix] [server_name]\n";
}

}  // namespace

int main(int argc, char* argv[]) {
    const char* transport_str = kDefaultTransport;
    const char* server_name = kDefaultServerName;
    enum transport_type type = TRANSPORT_TYPE_UNIX;

    if (argc > 1) {
        transport_str = argv[1];
    }
    if (argc > 2 && argv[2] && argv[2][0] != '\0') {
        server_name = argv[2];
    }

    if (!ResolveTransport(transport_str, &type)) {
        PrintUsage(argv[0]);
        return kFailureExitCode;
    }

    std::unique_ptr<mlink_server_t, ServerDeleter> server(mlink_server_init(type, server_name));
    if (!server) {
        std::cerr << "Failed to init mlink server\n";
        return kFailureExitCode;
    }

    DeviceContext ctx;
    if (!RegisterPickCubeTool(server.get(), &ctx)) {
        return kFailureExitCode;
    }

    std::cout << "lerobot_device registered tools: pick_cube\n";
    mlink_server_run(server.get());
    return kSuccessExitCode;
}
