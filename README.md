# Cafe Ordering Application

Python application that simulates self-service beverage ordering in a cafe via tablet. The project has been extended with Docker and Snap packaging for the Operating Systems course.

## Description

Each table in the cafe has a tablet where guests can independently order beverages through a graphical user interface without waiter assistance. The application supports parallel processing of multiple orders, simulating multiple tables ordering simultaneously.

The REST API server can be run directly with Python, inside a Docker container, or installed as a Snap package on any Linux distribution that supports snapd.

## Features

- Graphical user interface built with Tkinter library
- Left side: beverage selection, quantity input, order confirmation
- Right side: tabular display of orders with status
- Parallel order processing using asyncio
- Asynchronous menu fetching via REST API (aiohttp)
- Factory pattern for creating beverage objects
- Strategy pattern for price calculation (standard price, discount, happy hour)
- Decorators for logging function calls and exception handling
- Daily report export in CSV and PDF format
- Unit tests for key components
- Docker container for the REST API
- Snap package with the REST API as a system service

## Requirements

- Python 3.8 or higher
- Packages listed in requirements.txt
- Docker Engine 20.10+ (for the container)
- snapd and snapcraft (for building the Snap package)

## Installation

```bash
pip install -r requirements.txt
```

## Running

Start the main application:

```bash
python main.py
```

Start GUI directly:

```bash
python -m gui.tablet_gui
```

Start only the REST API server:

```bash
python -m services.api_server
```

The API server reads optional environment variables `API_HOST` (default `0.0.0.0`) and `API_PORT` (default `8080`).

## Testing

Run all tests:

```bash
pytest tests/ -v
```

Run individual tests:

```bash
pytest tests/test_pricing_strategies.py -v
pytest tests/test_order_service.py -v
pytest tests/test_beverage.py -v
```

## Docker

The repository contains a `Dockerfile`, `.dockerignore` and `docker-compose.yml` that package the REST API into a container. The GUI is not containerized because Tkinter requires a display server; only the headless API runs inside the container.

Build and run the container:

```bash
docker compose up --build
```

The image is based on `python:3.11-slim`. On the first build Docker downloads the base image and installs the Python dependencies, which takes a few minutes. Subsequent builds use the cache and finish in seconds.

The container exposes port 8080 and is mapped to port 8080 on the host. Once the container is running, you can test the endpoints:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/menu
curl http://localhost:8080/api/beverages/1
```

To stop and remove the container:

```bash
docker compose down
```

Useful commands while the container is running:

```bash
docker ps                       # list running containers
docker images                   # list local images
docker logs ordering-api        # view container logs
docker exec -it ordering-api sh # open a shell inside the container
```

The compose file also configures a healthcheck on `/health` that runs every 30 seconds.

## Snap

The repository contains `snap/snapcraft.yaml` describing a strictly confined Snap package. Two apps are defined:

- `api-server` runs as a `simple` daemon and starts automatically after installation
- `demo` is a CLI command that runs the included demo script

Build the Snap package (requires LXD as the build backend):

```bash
snapcraft pack --use-lxd
```

The build runs inside a clean LXD container so it does not depend on the host environment. The first build pulls the Ubuntu 22.04 image and takes around 5 to 10 minutes. The output is a file named `ordering-application_1.0.0_amd64.snap`.

Install the locally built Snap:

```bash
sudo snap install ordering-application_1.0.0_amd64.snap --dangerous
```

The `--dangerous` flag is required because the Snap is not signed by the Snap Store.

After installation the API server starts automatically. Verify with:

```bash
snap services ordering-application
sudo snap logs ordering-application.api-server
curl http://localhost:8080/health
```

Run the demo command:

```bash
ordering-application.demo
```

Other useful Snap commands:

```bash
snap list                                    # list installed snaps
snap info ordering-application               # details about the snap
snap connections ordering-application        # check granted plugs
sudo snap stop ordering-application.api-server
sudo snap start ordering-application.api-server
sudo snap remove ordering-application
```

The Snap requests `network` and `network-bind` interfaces, which are auto-connected on installation. No manual `snap connect` step is required.

### WSL note

Running snapd inside WSL2 requires systemd. Enable it once by adding the following to `/etc/wsl.conf`:

```
[boot]
systemd=true
```

Then run `wsl --shutdown` from PowerShell and reopen the Ubuntu terminal.

### Building for Raspberry Pi

The same `snapcraft.yaml` can be used to build a Snap for ARM devices like Raspberry Pi:

```bash
snapcraft pack --use-lxd --build-for=arm64
```

The resulting `.snap` file can be transferred to a Raspberry Pi running Ubuntu Core or Ubuntu Server and installed with `sudo snap install ... --dangerous`.

## REST API

The API server listens on `http://0.0.0.0:8080` by default. Host and port can be overridden with the `API_HOST` and `API_PORT` environment variables.

Endpoints:

- `GET /api/menu` - returns the full beverage menu with prices and happy hour status
- `GET /api/beverages/{id}` - returns details for a single beverage by id
- `GET /health` - returns service health status, used by the Docker healthcheck

Example response from `/health`:

```json
{"status": "ok", "service": "beverage-api"}
```

## Architecture

### Design Patterns

**Factory Pattern** - Creating beverage objects
- `models/factory.py` - BeverageFactory with metaclass registration
- `models/beverage.py` - Beverage classes (Coffee, Tea, Beer, etc.)

**Strategy Pattern** - Price calculation
- `services/pricing_strategy.py` - PricingContext and strategies
- StandardPricingStrategy - standard price
- HappyHourStrategy - discount (16:00-18:00)
- DiscountStrategy - percentage discount

**Decorator Pattern** - Function wrapping
- `decorators/logger.py` - logging function calls
- `decorators/exception_handler.py` - centralized exception handling

### Concurrency

The application uses `asyncio` for concurrent order processing. Multiple tablets can place orders simultaneously without blocking each other. The REST API is served with `aiohttp`, which is also based on asyncio.

## Project Structure

```
Ordering-Application-Docker-Snap/
├── main.py                 # Application entry point
├── requirements.txt        # Python dependencies
├── Dockerfile              # Docker image recipe
├── .dockerignore           # Files excluded from the Docker build context
├── docker-compose.yml      # Docker Compose configuration
├── snap/
│   └── snapcraft.yaml      # Snap package definition
├── services/
│   ├── api_server.py       # REST API server (aiohttp)
│   ├── order_service.py    # Order processing
│   └── pricing_strategy.py # Pricing strategies
├── models/
│   ├── beverage.py         # Beverage classes
│   └── factory.py          # BeverageFactory
├── decorators/
│   ├── logger.py
│   └── exception_handler.py
├── gui/
│   └── tablet_gui.py       # Tkinter GUI
├── demos/
│   ├── demo_complete.py
│   ├── demo_parallel_orders.py
│   └── demo_strategy_pattern.py
├── exporters/
│   ├── csv_exporter.py
│   └── pdf_exporter.py
├── tests/
│   ├── test_beverage.py
│   ├── test_order_service.py
│   └── test_pricing_strategies.py
└── reports/                # Generated CSV and PDF reports
```

## Technologies

- Python 3.8+
- Tkinter (GUI)
- asyncio (concurrency)
- aiohttp (REST API)
- pytest (testing)
- reportlab (PDF reports)
- Docker, Docker Compose
- Snapcraft, snapd, LXD

## Reports

Reports are generated in the `reports/` directory:

- CSV format with order details and statistics
- PDF format with formatted reports and tables
