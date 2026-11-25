# Serving the KG on keng.istc.cnr.it

The SPARQL endpoint and the linked data of the KG are served at `https://keng.istc.cnr.it/climate-change-kg/`, where
w3id.org redirects `https://w3id.org/climate-change-kg/sparql` and `https://w3id.org/climate-change-kg/data/...`. This
folder sets up the server: Ubuntu 24.04 LTS, 16 GB of RAM, 28.5 GB of disk.

```
                 ┌─────────────────────────────┐
  internet ─────▶│ nginx (Ubuntu package)      │  ports 80 and 443; certificate from Let's Encrypt,
                 │                             │  renewed by certbot.timer, nginx reloaded after
                 └──────────────┬──────────────┘
                                │ /climate-change-kg/...  →  127.0.0.1:8081/...
                 ┌──────────────▼──────────────────────────────────────────────┐
                 │ knowledge-graph-serve (Docker Compose)                      │
                 │ /srv/kgserve/climate-change-kg                              │
                 │                                                             │
                 │   web (nginx) ──▶ store: GraphDB 11.5.2, ruleset            │
                 │        │                 rdfsplus-optimized  ◀── sync ◀─────┼── Zenodo: latest release of
                 │        └────────▶ linked-data                               │   10.5281/zenodo.24305088
                 └─────────────────────────────────────────────────────────────┘
```

- **nginx**, installed on the server (not in a container), handles the host name, HTTPS and the old paths, and passes
  `/climate-change-kg/` to knowledge-graph-serve.
- **certbot**, also the Ubuntu package, gets the certificate with the HTTP challenge (webroot `/var/www/letsencrypt`,
  served by nginx on port 80). Its systemd timer (`certbot.timer`, twice a day) renews the certificate when it nears
  its expiry (30 days before, by default) and then reloads nginx. Nothing is done by hand.
- **[knowledge-graph-serve](https://github.com/miguel76/knowledge-graph-serve)** serves the KG from its Zenodo record,
  with this configuration (`kgserve/config.json`):

  ```json
  {"zenodo": "10.5281/zenodo.24305088", "inference": "rdfsplus-optimized", "describeInferred": false}
  ```

  The concept DOI always resolves to the latest release: the sync checks the record every hour and loads a new release
  as soon as it is published. The store is GraphDB, as the regime `rdfsplus-optimized` is one of its rulesets: the
  SPARQL endpoint answers with the inferred statements (`?infer=false` for the explicit ones only); the resource pages
  show the explicit statements (`?infer=true` adds the inferred ones). GraphDB replaces the KG in one transaction, so
  queries never see a partial release.

## What changes from climate-change-kg-docker

The previous setup, [climate-change-kg-docker](https://github.com/hacid-project/climate-change-kg-docker), ran
everything, the front nginx included, in one Docker Compose project.

| | climate-change-kg-docker | Now |
|:--|:--|:--|
| Front web server | nginx container | nginx on the server |
| Certificate renewal | by hand (`docker compose run certbot renew`, then a restart of nginx) | automatic (`certbot.timer`, then a reload of nginx) |
| New release of the KG | uploaded by hand in the GraphDB Workbench | loaded by the sync, within an hour of its publication on Zenodo |
| Linked data | LodView, built from a fork with Maven | knowledge-graph-serve, also in Turtle, JSON-LD, RDF/XML, N-Triples, ... |
| SPARQL editor | YASGUI container | knowledge-graph-serve |
| GraphDB Workbench | public, on port 7200, without authentication | on the server only (`127.0.0.1:7201`), through an SSH tunnel |
| Ports open to the internet | 80, 443, 7200, 8009, 8080, 8088 | 80, 443 |

The public paths:

| Path | Served by |
|:--|:--|
| `/climate-change-kg/` | landing page: the release served, statistics, named graphs, state of the sync (new) |
| `/climate-change-kg/sparql` | SPARQL endpoint (GET, POST, CORS); browsers are sent to the editor, as before |
| `/climate-change-kg/sparql-ui/` | SPARQL editor |
| `/climate-change-kg/id/...` | linked data; the URLs of LodView ending in `.html` still give the HTML page |
| `/climate-change-kg/status.json` | state of the sync (new) |
| `/hacid-cs-kg/...` | redirect (308) to `/climate-change-kg/...`, as before |
| `/` | redirect to `/climate-change-kg/` (was the default page of nginx) |
| `/climate-change-kg-cases/sparql`, `/hacid-cs-kg-cases/...` | not served: see [The cases endpoint](#the-cases-endpoint) |
| `/climate-change-kg/id/staticResources/`, `/static/`, `/manifest.json` | gone: files of LodView and YASGUI, which the new pages do not use |

## Files

| File | Installed as |
|:--|:--|
| `install.sh` | the script that installs everything below (run with `sudo`); it also pins the version of knowledge-graph-serve (`KGSERVE_REF`) |
| `kgserve/config.json` | `/srv/kgserve/climate-change-kg/config.json`: the KG served |
| `kgserve/compose.keng.yaml` | `/srv/kgserve/climate-change-kg/compose.keng.yaml`: settings of this server (Workbench port, rotation of the container logs) |
| `kgserve/compose.env` | `/srv/kgserve/climate-change-kg/.env`: the compose files used (GraphDB), the project name, the port (`127.0.0.1:8081`) |
| `nginx/keng-http.conf` | `/etc/nginx/sites-available/`: port 80, the challenges of Let's Encrypt and the redirect to HTTPS |
| `nginx/keng-https.conf` | `/etc/nginx/sites-available/`: port 443, the KG and the old paths |

`/srv/kgserve/climate-change-kg` is a clone of knowledge-graph-serve, at the commit given in `install.sh`. The data are
in its `data/` folder: `data/store` for GraphDB, `data/sync` for the state of the sync and the downloaded release.

Change these files here, in the repository, then pull and run `install.sh` again on the server: it overwrites the
installed copies.

## Requirements

| Requirement | Check |
|:--|:--|
| Docker Engine with the Compose plugin, 2.24.4 or later (for `!override` and `!reset` in the compose files) | `docker compose version` |
| The GraphDB license file (GraphDB 11 needs one, also for the free edition): the `graphdb.license` of the climate-change-kg-docker folder | |
| Ports 80 and 443 reachable from the internet (as today) | |
| Free disk for the GraphDB image and a second copy of the KG while both setups run | `df -h /`, `sudo docker system df` |

Memory: GraphDB has a 4 GB heap (`GDB_JAVA_OPTS` in `compose.graphdb.yaml` of knowledge-graph-serve); the other
services take less than 1 GB. While the new setup and the old one both run, there are two GraphDBs: 16 GB should be enough.

## Install, moving from climate-change-kg-docker

The new setup starts next to the old one, which keeps serving until the switch. The switch itself takes about a
minute of downtime.

### 1. Get this repository on the server

```bash
git clone https://github.com/hacid-project/climate-change-kg.git
```

```bash
cd climate-change-kg
```

All the commands below are run from there, except where a `cd` says otherwise.

### 2. Start knowledge-graph-serve

```bash
sudo deployment/install.sh kgserve
```

The first time, it clones knowledge-graph-serve into `/srv/kgserve/climate-change-kg` and stops, asking for the
GraphDB license. Copy the one of the old setup (give the path of the climate-change-kg-docker folder):

```bash
sudo cp /path/to/climate-change-kg-docker/graphdb.license /srv/kgserve/climate-change-kg/
```

Then run it again: it builds the image and starts the services.

```bash
sudo deployment/install.sh kgserve
```

The sync downloads the latest release from Zenodo and loads it into GraphDB, which computes the inferences while
loading. Follow it with:

```bash
cd /srv/kgserve/climate-change-kg && sudo docker compose logs -f sync
```

It is done at `Loaded ... statements from record ...`; `"status": "ok"` in:

```bash
curl -s http://127.0.0.1:8081/status.json
```

### 3. Check it before the switch

On the server:

```bash
curl -s -H 'Accept: text/csv' --data-urlencode 'query=SELECT (COUNT(*) AS ?n) {?s a ?c}' http://127.0.0.1:8081/sparql
```

```bash
curl -s -H 'Accept: text/turtle' http://127.0.0.1:8081/id/models/HadCM3
```

To browse it, open a tunnel from your computer, then open <http://localhost:8081/>:

```bash
ssh -N -L 8081:127.0.0.1:8081 keng.istc.cnr.it
```

### 4. Switch

Stop the old setup (all its containers: nginx, GraphDB, LodView, YASGUI), from its folder:

```bash
cd /path/to/climate-change-kg-docker && sudo docker compose down
```

Then install nginx and certbot, and get the certificate:

```bash
sudo deployment/install.sh front
```

It refuses to start if something else still listens on port 80 or 443. It installs the two nginx sites (and removes
the default site of Ubuntu), serves port 80 alone until it has the certificate, gets it from Let's Encrypt, then
turns on port 443, and ends with a dry run of the renewal. Running it means accepting the
[terms of Let's Encrypt](https://letsencrypt.org/repository/). The account is registered without an email address
(Let's Encrypt no longer sends expiry reminders); to give one, run it as
`sudo CERTBOT_EMAIL=<address> deployment/install.sh front`.

To go back to the old setup, if needed:

```bash
sudo systemctl stop nginx
```

```bash
cd /path/to/climate-change-kg-docker && sudo docker compose up -d
```

### 5. Check it in public

```bash
curl -sI https://keng.istc.cnr.it/climate-change-kg/
```

```bash
curl -sL -H 'Accept: text/turtle' https://w3id.org/climate-change-kg/data/models/HadCM3
```

```bash
curl -sL -G -H 'Accept: text/csv' --data-urlencode 'query=ASK {?s ?p ?o}' https://w3id.org/climate-change-kg/sparql
```

```bash
systemctl list-timers certbot.timer
```

### 6. Clean up, after a few days

Remove the images of the old setup that are no longer used:

```bash
sudo docker image rm lodview mathiasvda/yasgui nginx:latest certbot/certbot:latest
```

The old GraphDB data (`data/` in the climate-change-kg-docker folder) hold the repositories of the old setup,
`climate-change-kg-write` (the cases) included: delete them only once the cases are no longer needed (see below). The
old certificates (`certbot/`) are no longer used.

## Operations

All the `docker compose` commands are run in `/srv/kgserve/climate-change-kg`, where `.env` selects the right compose
files; `sudo` is needed unless your user is in the group `docker`.

| Task | How |
|:--|:--|
| Publish a new release of the KG | nothing to do: the sync loads it within an hour of its publication on Zenodo |
| Load it now | `sudo docker compose kill -s HUP sync` |
| Reload the current release | `sudo docker compose kill -s USR1 sync` |
| See the state of the sync | `https://keng.istc.cnr.it/climate-change-kg/status.json`, the landing page, or `sudo docker compose logs -f sync` |
| Change the configuration of the KG | edit `deployment/kgserve/config.json` here, commit, pull on the server, run `sudo deployment/install.sh kgserve` (it restarts the sync and the linked data; with a new `inference`, the sync recreates the GraphDB repository and loads the release again) |
| Update knowledge-graph-serve | set `KGSERVE_REF` in `install.sh` to the new commit, commit, pull on the server, run `sudo deployment/install.sh kgserve` |
| Change the nginx sites | edit `deployment/nginx/`, commit, pull on the server, run `sudo deployment/install.sh front` |
| Check the certificate | `sudo certbot certificates`; `sudo certbot renew --dry-run` tests the renewal |
| Use the GraphDB Workbench | `ssh -N -L 7201:127.0.0.1:7201 keng.istc.cnr.it` from your computer, then <http://localhost:7201/> (repository `kg`) |
| Give GraphDB more memory | add `environment: {GDB_JAVA_OPTS: -Xmx6g}` to `store` in `kgserve/compose.keng.yaml`, then run `install.sh kgserve` |
| Logs of the web server | `/var/log/nginx/` (rotated by logrotate); the container logs are rotated by Docker (`compose.keng.yaml`) |

After a reboot, nginx, certbot.timer and Docker start by themselves, and Docker restarts the containers.

## The cases endpoint

The old setup also published `/climate-change-kg-cases/sparql` (and `/hacid-cs-kg-cases/...`): the GraphDB repository
`climate-change-kg-write`, used by the HACID DSS for its cases. It is not part of the KG released on Zenodo, so
knowledge-graph-serve does not serve it, and this setup does not publish it (404). To keep it:

1. in `docker-compose.yaml` of climate-change-kg-docker, publish GraphDB on the server only
   (`ports: ['127.0.0.1:7200:7200']`), then start only GraphDB:

   ```bash
   cd /path/to/climate-change-kg-docker && sudo docker compose up -d triplestore
   ```

2. uncomment the two locations at the end of `nginx/keng-https.conf`, and run `sudo deployment/install.sh front`.
