# Overview

Dead simple [Elixir](http://elixir-lang.github.io) wrapper for the
[ProfitBricks API](https://devops.profitbricks.com/api/cloud/v4).

## Installation

First, add ProfitBricks to your `mix.exs` dependencies:

```elixir
def deps do
  [{:profitbricks, "~> 0.1"}]
end
```
Then, update your dependencies:

```sh
$ mix deps.get
```

## Configuration

See the [sample configuration](config/config.sample.exs)

Edit to taste.

## Usage

The library leverages the [Tesla](https://github.com/teamon/tesla) HTTP
library, and for now it simply wraps the Tesla GET/POST/etc methods
directly.

The path and JSON data parameters can be figured out via ProfitBricks's
[API](https://devops.profitbricks.com/api/cloud/v4).

### Examples

```elixir
# Get datacenters info.
{:ok, response} = ProfitBricks.get("/datacenters")
IO.puts response.status
IO.inspect response.headers
IO.inspect response.body
# First datacenter.
datacenter = Enum.at(response.body["items"], 0)
datacenter_id = datacenter["id"]

#Get servers in datacenter.
{:ok, response} = ProfitBricks.get("/datacenters/#{datacenter_id}/servers")
# First server.
server = Enum.at(response.body["items"], 0)
server_id = server["id"]

# Get server.
{:ok, response} = ProfitBricks.get("/datacenters/#{datacenter_id}/servers/#{server_id}")
cores = response.body["properties"]["cores"]

# Update server.
data = %{
  properties: %{
    cores: 4,
    ram: 8192,
  },
}
{:ok, response} = ProfitBricks.put("/datacenters/#{datacenter_id}/servers/#{server_id}", data)
cores = response.body["properties"]["cores"]

# Get images.
{:ok, response} = ProfitBricks.get("/images")
Enum.each response.body["items"], fn image ->
  IO.inspect image
end
# First image.
image = Enum.at(response.body["items"], 0)
image_id = image["id"]

# Get snapshots.
{:ok, response} = ProfitBricks.get("/snapshots")
# First snapshot.
snapshot = Enum.at(response.body["items"], 0)
snapshot_id = snapshot["id"]

# Create volume using snapshot.
data = %{
  properties: %{
    name: "example-volume",
    size: 20,
    image: snapshot_id,
    type: "HDD",
  }
}
{:ok, response} = ProfitBricks.post("/datacenters/#{datacenter_id}/volumes", data)
volume_id = response.body["id"]

# Create public LAN.
data = %{
  properties: %{
    name: "Example LAN",
    public: true,
  }
}
{:ok, response} = ProfitBricks.post("/datacenters/#{datacenter_id}/lans", data)
lan_id = response.body["id"]

# Create server, attaching previously created volume/LAN.
data = %{
  properties: %{
    cores: 2,
    ram: 4096,
    name: "Example server",
    bootVolume: %{
      id: volume_id,
    },
  },
  entities: %{
    nics: %{
      items: [
        %{
          properties: %{
            name: "Example NIC",
            dhcp: true,
            lan: lan_id,
            nat: false,
          },
        },
      ],
    },
  },
}
{:ok, response} = ProfitBricks.post("/datacenters/#{datacenter_id}/servers", data)
server_id = response.body["id"]
{:ok, response} = ProfitBricks.get("/datacenters/#{datacenter_id}/servers/#{server_id}", query: [depth: 3])
Apex.ap(response.body)
public_ip = Enum.at(Enum.at(response.body["entities"]["nics"]["items"], 0)["properties"]["ips"] , 0)
server_state = response.body["metadata"]["state"]
vm_state = response.body["properties"]["vmState"]

# Stop server. Note, don't pass any data here.
{:ok, response} = ProfitBricks.post("/datacenters/#{datacenter_id}/servers/#{server_id}/stop")

# Delete server.
{:ok, response} = ProfitBricks.delete("/datacenters/#{datacenter_id}/servers/#{server_id}")

# Clean up created LAN and volume.
{:ok, response} = ProfitBricks.delete("/datacenters/#{datacenter_id}/lans/#{lan_id}")
{:ok, response} = ProfitBricks.delete("/datacenters/#{datacenter_id}/volumes/#{volume_id}")

```
