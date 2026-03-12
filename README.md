# RADKit MCP Server

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python)](https://www.python.org/)
[![MCP](https://img.shields.io/badge/Protocol-MCP-green)](https://modelcontextprotocol.io/)

A **Model Context Protocol (MCP) server** that bridges AI assistants (such as Claude, Cursor, or any MCP-compatible client) with **Cisco RADKit** — enabling AI-driven network device interaction, diagnostics, and automation through natural language.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Docker Usage](#docker-usage)
- [Connecting an MCP Client](#connecting-an-mcp-client)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [Related Projects](#related-projects)
- [License](#license)

---

## Overview

**RADKit** (Remote Access & Diagnostics Kit) is a Cisco tool that provides secure, zero-trust remote access to network devices. This project wraps the [RADKit MCP Server Community](https://github.com/CiscoDevNet/radkit-mcp-server-community) package into a Docker-ready deployment, exposing RADKit capabilities as an MCP server.

With this integration, AI assistants can:

- 🔍 **Query network devices** — run show commands, retrieve device state
- 🛠️ **Diagnose network issues** — leverage AI reasoning over live device data
- ⚙️ **Automate network operations** — execute workflows through natural language instructions
- 🔐 **Securely access devices** — all traffic tunneled through RADKit's zero-trust infrastructure

---

## Architecture

```
┌─────────────────────┐      MCP/stdio       ┌──────────────────────┐
│   AI Assistant      │◄────────────────────►│  RADKit MCP Server   │
│ (Claude, Cursor...) │                      │    (this project)    │
└─────────────────────┘                      └──────────┬───────────┘
                                                        │ RADKit API
                                                        ▼
                                           ┌────────────────────────┐
                                           │  Cisco RADKit Cloud    │
                                           └────────────┬───────────┘
                                                        │
                                                        ▼
                                           ┌────────────────────────┐
                                           │    Network Devices     │
                                           │ (Routers, Switches...) │
                                           └────────────────────────┘
```

---

## Prerequisites

Before getting started, ensure you have:

- **Docker** and **Docker Compose** installed ([Install Docker](https://docs.docker.com/get-docker/))
- A valid **Cisco RADKit account** with:
  - A RADKit **Service Serial** number
  - A RADKit **Identity** (email/CCO ID)
  - Your RADKit **client private key password**
- Access to a **RADKit-enrolled network device**

> 💡 New to RADKit? Visit [Cisco RADKit documentation](https://developer.cisco.com/radkit/) to get started.

---

## Quick Start

### 1. Clone the repository (with submodules)

```bash
git clone --recurse-submodules https://github.com/kickouille/radkit-mcp.git
cd radkit-mcp
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Configure environment variables

Edit `compose.yml` and fill in your RADKit credentials:

```bash
RADKIT_MCP_SERVICE_SERIAL=<your-service-serial>
RADKIT_MCP_IDENTITY=<your-radkit-identity>
RADKIT_MCP_CLIENT_PRIVATE_KEY_PASSWORD=<your-private-key-password>
```

> ⚠️ **Security Note:** Consider using a `.env` file or Docker secrets instead of hardcoding credentials in `compose.yml`.

### 3. Build and run

```bash
docker compose up --build
```

---

## Configuration

The server is configured through environment variables:

| Variable | Required | Description |
|---|---|---|
| `RADKIT_MCP_SERVICE_SERIAL` | ✅ Yes | Your RADKit service serial number |
| `RADKIT_MCP_IDENTITY` | ✅ Yes | Your RADKit identity (CCO ID / email) |
| `RADKIT_MCP_CLIENT_PRIVATE_KEY_PASSWORD` | ✅ Yes | Password for your RADKit client private key |

### Persistent Credentials Volume

RADKit credentials are stored in a Docker volume (`radkit-credentials`) mounted at `/root/.radkit` inside the container. This ensures credentials persist across container restarts.

---

## Docker Usage

### Build the image manually

```bash
docker build -t radkit-mcp .
```

### Run with Docker Compose

```bash
# Start in foreground
docker compose up

# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Run the container directly

```bash
docker run -it \
  -e RADKIT_MCP_SERVICE_SERIAL=your-serial \
  -e RADKIT_MCP_IDENTITY=your-identity \
  -e RADKIT_MCP_CLIENT_PRIVATE_KEY_PASSWORD=your-password \
  -v radkit-credentials:/root/.radkit \
  radkit-mcp
```

---

## Connecting an MCP Client

### Claude Desktop

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "radkit": {
      "command": "docker",
      "args": [
        "compose",
        "-f", "/path/to/radkit-mcp/compose.yml",
        "run", "--rm", "-i",
        "radkit-mcp"
      ]
    }
  }
}
```

### Cursor / Other MCP Clients

Configure your MCP client to launch the Docker container as a stdio-based MCP server. The container is pre-configured with `stdin_open: true` and `tty: true` for interactive use.

---

## Project Structure

```
radkit-mcp/
├── .gitmodules                      # Git submodule configuration
├── Dockerfile                       # Docker image definition
├── compose.yml                      # Docker Compose service definition
├── README.md                        # This file
└── radkit-mcp-server-community/     # Git submodule (CiscoDevNet)
    # Core MCP server Python package (radkit_mcp)
```

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the server image using `uv` on Python 3.12 slim |
| `compose.yml` | Defines the Docker service, env vars, and persistent volume |
| `radkit-mcp-server-community/` | Submodule with the `radkit_mcp` Python package from CiscoDevNet |

---

## How It Works

1. **Docker builds** the image by installing the `radkit-mcp-server-community` Python package using [`uv`](https://github.com/astral-sh/uv)
2. **At runtime**, the container launches `python -m radkit_mcp`, starting the MCP server
3. The MCP server **communicates with an AI client over stdio**, following the [Model Context Protocol](https://modelcontextprotocol.io/)
4. When the AI issues tool calls, the MCP server **authenticates with Cisco RADKit** using the provided credentials and proxies commands to enrolled network devices
5. **Results are returned** to the AI client as structured MCP responses

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to your branch (`git push origin feature/my-feature`)
5. Open a Pull Request

For issues with the core MCP server logic, please contribute to the upstream repository:
👉 [CiscoDevNet/radkit-mcp-server-community](https://github.com/CiscoDevNet/radkit-mcp-server-community)

---

## Related Projects

- 🔗 [CiscoDevNet/radkit-mcp-server-community](https://github.com/CiscoDevNet/radkit-mcp-server-community) — Core MCP server implementation
- 🔗 [Cisco RADKit](https://developer.cisco.com/radkit/) — Official RADKit documentation
- 🔗 [Model Context Protocol](https://modelcontextprotocol.io/) — MCP specification

---

## License

This project is licensed under the **Apache License 2.0**.

The `radkit-mcp-server-community` submodule is maintained by Cisco DevNet and is subject to its own license terms.

---

<div align="center">
Made with ❤️ for the network automation community
</div>
