"""Release of the Climate Change Knowledge Graph (rules/release.smk).

A release makes everything coherent: the git repository (a release commit,
tagged v<version>, with the changelog, the citation file, the release notes and
the data of the website), the record of the KG on Zenodo (a new version, with
the dump and its description, whose metadata say which release they are), and
the record of the workflow on Zenodo (archived from the GitHub release of the
tag by the Zenodo GitHub integration).

Each step is a subcommand, run by a rule of rules/release.smk, that records its
result in the state directory (kg/release/<version>/), so that a release
interrupted by an error resumes from the step that failed:

  check    the preconditions: version, git repository, changelog, tokens
  draft    a new version of the record of the KG on Zenodo, as a draft, with
           its DOI reserved
  commit   the release commit (changelog, CITATION.cff, release notes, data of
           the website) and its tag, local only
  upload   the files of the KG (built at the release commit) and the metadata
           to the draft: the draft can be reviewed on Zenodo
  github   the commit and the tag pushed, the GitHub release made, and the DOI
           of the workflow waited for (the Zenodo GitHub integration archives
           the release)
  publish  the version of the KG published on Zenodo, with the DOI of the
           workflow, and checked
  discard  undoes a release that is not public yet: deletes the draft, the
           local tag and the release commit (if not pushed), and the state

Needs the environment variable ZENODO_TOKEN (or the one named by the
configuration, release.zenodo_token_env), a Zenodo personal access token with
the scopes deposit:write and deposit:actions, and the GitHub CLI (gh),
authenticated with the right to push to the repository.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import string
import subprocess
import sys
import time

import markdown
import rdflib
import requests
import yaml

VOID = rdflib.Namespace("http://rdfs.org/ns/void#")
SD = rdflib.Namespace("http://www.w3.org/ns/sparql-service-description#")
SH = rdflib.Namespace("http://www.w3.org/ns/shacl#")
DCTERMS = rdflib.Namespace("http://purl.org/dc/terms/")
KG = rdflib.URIRef("https://w3id.org/climate-change-kg/data/kg")

SEMVER = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$")

# Files written by the release commit
CHANGELOG = "CHANGELOG.md"
CITATION = "CITATION.cff"
NOTES = "publication/releases/v{version}.md"
WEBSITE_DATA = "website/_data/releases.json"
NOTES_TEMPLATE = "publication/templates/release-notes.md"
DESCRIPTION_TEMPLATE = "publication/templates/zenodo-description.md"
RECORD = "metadata/record.yaml"


class ReleaseError(Exception):
    pass


def log(message):
    print(f"[release] {message}", file=sys.stderr, flush=True)


# --- Small utilities


def run(*args, check=True, capture=True):
    """Runs a command, returning its standard output (stripped)."""
    result = subprocess.run(args, capture_output=capture, text=True)
    if check and result.returncode != 0:
        raise ReleaseError(f"{' '.join(args)} failed:\n{result.stderr.strip() if capture else ''}")
    return result.stdout.strip() if capture else ""


def git(*args, check=True):
    return run("git", *args, check=check)


def read_json(path):
    with open(path) as f:
        return json.load(f)


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".tmp", "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(path + ".tmp", path)


def semver_key(version):
    match = SEMVER.match(version.lstrip("v"))
    if not match:
        return None
    major, minor, patch, pre = match.groups()
    # A pre-release comes before the release (1.1.0-rc1 < 1.1.0)
    return (int(major), int(minor), int(patch), 0 if pre else 1, pre or "")


def md5(path):
    digest = hashlib.md5()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def today():
    return datetime.datetime.now(datetime.timezone.utc).date().isoformat()


# --- Zenodo (REST API of depositions and records)


class Zenodo:
    def __init__(self, url, token=None):
        self.url = url.rstrip("/")
        self.api = self.url + "/api"
        self.session = requests.Session()
        if token:
            self.session.headers["Authorization"] = f"Bearer {token}"

    def request(self, method, url, expect=(200, 201, 202, 204), **kwargs):
        if not url.startswith("http"):
            url = self.api + url
        data_path = kwargs.pop("data_path", None)
        for attempt in range(5):
            if data_path:
                # A file to send: opened again at each attempt
                with open(data_path, "rb") as data:
                    response = self.session.request(method, url, timeout=3600, data=data, **kwargs)
            else:
                response = self.session.request(method, url, timeout=600, **kwargs)
            if response.status_code in (429, 500, 502, 503, 504) and attempt < 4:
                time.sleep(10 * (attempt + 1))
                continue
            break
        if response.status_code not in expect:
            raise ReleaseError(f"Zenodo: {method} {url} returned {response.status_code}: {response.text[:2000]}")
        return response.json() if response.content and "json" in response.headers.get("Content-Type", "") else None

    def latest(self, concept):
        """The latest published version of a concept record."""
        return self.request("GET", f"/records/{concept}", allow_redirects=True)

    def versions(self, concept):
        result = self.request(
            "GET", "/records", params={"q": f"conceptrecid:{concept}", "all_versions": "true", "size": 25}
        )
        return result["hits"]["hits"]

    def deposition(self, deposition_id):
        return self.request("GET", f"/deposit/depositions/{deposition_id}")

    def new_version(self, latest_id, concept):
        """A draft of a new version of the record (an existing one if any)."""
        try:
            response = self.request("POST", f"/deposit/depositions/{latest_id}/actions/newversion")
            return self.request("GET", response["links"]["latest_draft"])
        except ReleaseError as error:
            # A draft of a new version may exist already: look for it
            drafts = self.request("GET", "/deposit/depositions", params={"status": "draft", "size": 100})
            for draft in drafts or []:
                if str(draft.get("conceptrecid")) == str(concept):
                    return draft
            raise error

    def new_deposition(self):
        return self.request("POST", "/deposit/depositions", json={})

    def delete_files(self, deposition):
        for file in self.deposition(deposition["id"]).get("files", []):
            self.request("DELETE", f"/deposit/depositions/{deposition['id']}/files/{file['id']}")

    def upload(self, deposition, path, name):
        return self.request(
            "PUT",
            f"{deposition['links']['bucket']}/{name}",
            data_path=path,
            headers={"Content-Type": "application/octet-stream"},
        )

    def set_metadata(self, deposition_id, metadata):
        return self.request("PUT", f"/deposit/depositions/{deposition_id}", json={"metadata": metadata})

    def publish(self, deposition_id):
        return self.request("POST", f"/deposit/depositions/{deposition_id}/actions/publish")

    def delete(self, deposition_id):
        return self.request("DELETE", f"/deposit/depositions/{deposition_id}", expect=(201, 204, 410))


def zenodo_client(cfg, need_token=True):
    release = cfg["release"]
    token = os.environ.get(release.get("zenodo_token_env", "ZENODO_TOKEN"))
    if need_token and not token:
        raise ReleaseError(
            f"Set the environment variable {release.get('zenodo_token_env', 'ZENODO_TOKEN')} to a Zenodo token"
            f" of {release['zenodo_url']} (scopes deposit:write, deposit:actions)"
        )
    return Zenodo(release["zenodo_url"], token)


# --- The facts of a release, from the build and the configuration


def changes(version):
    """The changes of the release in CHANGELOG.md: its section, or else the
    section Unreleased (before the release commit moves it)."""
    with open(CHANGELOG) as f:
        text = f.read()
    sections = re.split(r"^## ", text, flags=re.M)
    for heading in (version, "Unreleased"):
        for section in sections[1:]:
            title, _, body = section.partition("\n")
            if title.split(" ")[0].strip("[]") == heading:
                return body.strip()
    return ""


def statistics(path, kg_ttl):
    """The triples of the KG and of each named graph, with their titles."""
    graph = rdflib.Graph()
    graph.parse(path, format="turtle")
    graph.parse(kg_ttl, format="turtle")
    triples = int(graph.value(KG, VOID.triples))
    graphs = []
    for named in graph.objects(KG, SD.namedGraph):
        name = str(graph.value(named, SD.name))
        dataset = graph.value(named, SD.graph)
        title = graph.value(dataset, DCTERMS.title) or ""
        graphs.append({"name": name, "title": str(title), "triples": int(graph.value(dataset, VOID.triples))})
    graphs.sort(key=lambda g: g["name"])
    return triples, graphs


def validation(summary_path, shapes_path):
    results = {"violations": 0, "warnings": 0, "infos": 0}
    for binding in read_json(summary_path)["results"]["bindings"]:
        severity = binding["severity"]["value"].rsplit("#", 1)[-1]
        key = {"Violation": "violations", "Warning": "warnings", "Info": "infos"}[severity]
        results[key] += int(binding["results"]["value"])
    shapes = rdflib.Graph()
    shapes.parse(shapes_path, format="turtle")
    results["node_shapes"] = len(set(shapes.subjects(rdflib.RDF.type, SH.NodeShape)))
    results["property_shapes"] = len(set(shapes.subjects(rdflib.RDF.type, SH.PropertyShape)))
    return results


def figures(path):
    binding = read_json(path)["results"]["bindings"][0]
    return {key: int(value["value"]) for key, value in binding.items()}


def sources(cfg, cmor_previous_editions):
    def short(commit):
        return commit[:7]

    def page(repo):
        return re.sub(r"\.git$", "", repo)

    eras = {era["era"]: era for era in cfg["eras"]}
    current = eras[cfg["current"]]
    labels = {"cmip5": "CMIP5", "cmip6": "CMIP6", "cmip6plus": "CMIP6Plus"}
    return {
        "ontologies_repo": page(cfg["ontologies"]["repo"]),
        "ontologies_commit": cfg["ontologies"]["version"],
        "ontologies_commit_short": short(cfg["ontologies"]["version"]),
        "cf_standard_names_version": str(cfg["cf_standard_names"]["version"]),
        "cmor_tables_current": f"{labels.get(current['era'], current['era'])} {current.get('version', '')}".strip(),
        "cmor_tables_previous_editions": cmor_previous_editions,
        "esgf_config_repo": page(cfg["cmip5_cvs"]["esgf_config_repo"]),
        "esgf_config_commit": short(cfg["cmip5_cvs"]["esgf_config_version"]),
        "cordex_domains_repo": page(cfg["cordex_domains"]["repo"]),
        "cordex_domains_commit": short(cfg["cordex_domains"]["version"]),
        "cordex_rcms_repo": page(cfg["cordex_cmip5_cvs"]["repo"]),
        "cordex_rcms_commit": short(cfg["cordex_cmip5_cvs"]["version"]),
        "cmip5_snapshot_doi": f"10.5281/zenodo.{cfg['cmip5']['snapshot']}",
        "cordex_cmip5_snapshot_doi": f"10.5281/zenodo.{cfg['cordex_cmip5']['snapshot']}",
        "ukcp18_snapshot_doi": f"10.5281/zenodo.{cfg['ukcp18']['snapshot']}",
    }


def facts(args, cfg, state):
    """Everything known about the release: the inputs of the notes, of the
    description on Zenodo and of the data of the website."""
    triples, graphs = statistics(args.statistics, "metadata/kg.ttl")
    draft = state.get("draft", {})
    previous = state["checked"].get("previous")
    workflow = state.get("github", {})
    return {
        "version": args.version,
        "date": state["checked"]["date"],
        "doi": draft.get("doi"),
        "url": draft.get("url"),
        "concept_doi": draft.get("concept_doi"),
        "previous": previous,
        "repository": f"https://github.com/{cfg['release']['github_repo']}",
        "workflow_concept_doi": cfg["release"].get("workflow_concept_doi"),
        "workflow_doi": workflow.get("workflow_doi"),
        "triples": triples,
        "graphs": graphs,
        "validation": validation(args.validation, args.shapes),
        "figures": figures(args.figures),
        "sources": sources(cfg, args.cmor_previous_editions),
        "changes": changes(args.version),
    }


def number(n):
    return f"{n:,}"


def about_millions(n):
    return f"about {n / 1e6:.1f} million"


def render(template_path, f, heading_shift=0):
    """Renders a template ($name placeholders, string.Template) with the
    facts, flattened and formatted. The headings of the changes (from
    CHANGELOG.md, ### and below) are moved down by heading_shift levels."""
    s = f["sources"]
    v = f["validation"]
    fig = f["figures"]
    tag_url = f"{f['repository']}/tree/v{f['version']}"
    if f.get("workflow_doi"):
        workflow = f"[workflow of the CCKG, v{f['version']}](https://doi.org/{f['workflow_doi']})"
    else:
        workflow = f"[workflow of the CCKG, tag v{f['version']}]({tag_url})"
    previous = f["previous"]
    values = {
        "version": f["version"],
        "date": f["date"],
        "doi": f["doi"] or "(to be assigned)",
        "doi_link": f"[{f['doi']}](https://doi.org/{f['doi']})" if f["doi"] else "(to be assigned)",
        "concept_doi_link": (
            f"[{f['concept_doi']}](https://doi.org/{f['concept_doi']})" if f["concept_doi"] else "(this record)"
        ),
        "previous_version": previous["version"] if previous else "none",
        "previous_link": (
            f"[{previous['version']}](https://doi.org/{previous['doi']})" if previous else "none (first release)"
        ),
        "workflow_link": workflow,
        "workflow_concept_link": (
            f"[{f['workflow_concept_doi']}](https://doi.org/{f['workflow_concept_doi']})"
            if f.get("workflow_concept_doi")
            else f"[{f['repository']}]({f['repository']})"
        ),
        "tag_link": f"[v{f['version']}]({tag_url})",
        "repository": f["repository"],
        "triples": number(f["triples"]),
        "triples_about": about_millions(f["triples"]),
        "named_graphs": number(len(f["graphs"])),
        "graphs_table": "\n".join(
            ["| Named graph | Content | Triples |", "|:--|:--|--:|"]
            + [f"| `{g['name']}` | {g['title']} | {number(g['triples'])} |" for g in f["graphs"]]
        ),
        "violations": number(v["violations"]),
        "warnings": number(v["warnings"]),
        "infos": number(v["infos"]),
        "node_shapes": number(v["node_shapes"]),
        "property_shapes": number(v["property_shapes"]),
        "changes": re.sub(
            r"^(#+) ", lambda m: "#" * (len(m.group(1)) + heading_shift) + " ", f["changes"] or "No changes recorded.",
            flags=re.M,
        ),
    }
    values.update({key: number(value) for key, value in fig.items()})
    values.update({key: value if isinstance(value, str) else number(value) for key, value in s.items()})
    with open(template_path) as t:
        return string.Template(t.read()).substitute(values)


def zenodo_metadata(cfg, f, reserve=False):
    """The metadata of the version on Zenodo: metadata/record.yaml and what
    the configuration and the build give."""
    with open(RECORD) as r:
        record = yaml.safe_load(r)
    # The changes are under a heading of level 4 (#### Changes)
    description = markdown.markdown(
        render(DESCRIPTION_TEMPLATE, f, heading_shift=2), extensions=["tables", "fenced_code"]
    )
    related = [
        {
            "identifier": f["sources"][f"{name}_snapshot_doi"],
            "relation": "isDerivedFrom",
            "resource_type": "dataset",
            "scheme": "doi",
        }
        for name in ("cmip5", "cordex_cmip5", "ukcp18")
    ]
    ontologies = cfg["ontologies"]
    if ontologies.get("doi"):
        related.append({"identifier": ontologies["doi"], "relation": "requires", "resource_type": "software", "scheme": "doi"})
    else:
        related.append(
            {
                "identifier": f"{f['sources']['ontologies_repo']}/tree/{ontologies['version']}",
                "relation": "requires",
                "resource_type": "software",
                "scheme": "url",
            }
        )
    if cfg["metadata"].get("website_url"):
        related.append(
            {"identifier": cfg["metadata"]["website_url"], "relation": "isDocumentedBy", "resource_type": "other", "scheme": "url"}
        )
    if f.get("workflow_doi"):
        related.append({"identifier": f["workflow_doi"], "relation": "isCompiledBy", "resource_type": "software", "scheme": "doi"})
    else:
        related.append(
            {
                "identifier": f"{f['repository']}/tree/v{f['version']}",
                "relation": "isCompiledBy",
                "resource_type": "software",
                "scheme": "url",
            }
        )
    related += record.get("related_identifiers") or []
    metadata = {
        "upload_type": "dataset",
        "title": record["title"],
        "creators": [
            {key: c[key] for key in ("name", "affiliation", "orcid") if c.get(key)} for c in record["creators"]
        ],
        "description": description,
        "access_right": "open",
        "license": record["license"],
        "keywords": record["keywords"],
        "language": record.get("language", "eng"),
        "version": f["version"],
        "publication_date": f["date"],
        "related_identifiers": related,
    }
    # Grants and communities exist on zenodo.org, not necessarily on the sandbox
    if not cfg["release"].get("sandbox"):
        if record.get("grants"):
            metadata["grants"] = [{"id": grant} for grant in record["grants"]]
        if record.get("communities"):
            metadata["communities"] = [{"identifier": c} for c in record["communities"]]
    if reserve:
        metadata["prereserve_doi"] = True
    return metadata


# --- The steps


def load_state(args):
    state = {}
    for step in ("checked", "draft", "commit", "upload", "github", "publish"):
        path = os.path.join(args.state, f"{step}.json")
        if os.path.exists(path):
            state[step] = read_json(path)
    return state


def step_check(args, cfg, state):
    release = cfg["release"]
    version = args.version
    if "commit" in state:
        # The release is under way: the repository has its commit, which the
        # checks would refuse
        commit = state["commit"]["commit"]
        if subprocess.run(["git", "merge-base", "--is-ancestor", commit, "HEAD"]).returncode != 0:
            raise ReleaseError(f"The release commit {commit[:7]} is not in HEAD: discard the release and start again")
        log(f"Release {version} under way (commit {commit[:7]}): resuming")
        return
    if not semver_key(version):
        raise ReleaseError(f"{version} is not a version X.Y.Z (or X.Y.Z-pre)")
    tag = f"v{version}"
    problems = []

    # The git repository: clean, on the branch of the releases, in sync
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    if branch != release["branch"]:
        problems.append(f"The current branch is {branch}, not {release['branch']}")
    status = git("status", "--porcelain")
    if status:
        problems.append("The working tree is not clean (commit or stash first):\n" + status)
    if release.get("push", True):
        git("fetch", "--quiet", "--tags", release["remote"], release["branch"])
        if git("rev-parse", "HEAD") != git("rev-parse", f"{release['remote']}/{release['branch']}"):
            problems.append(f"HEAD is not {release['remote']}/{release['branch']}: pull or push first")
    if git("rev-parse", "-q", "--verify", f"refs/tags/{tag}", check=False):
        problems.append(f"The tag {tag} exists already")
    tags = [t for t in git("tag", "--list", "v*").split() if semver_key(t)]
    newer = [t for t in tags if semver_key(t) >= semver_key(version)]
    if newer:
        problems.append(f"{version} is not after the existing tags {', '.join(newer)}")

    # The changes, written by hand in CHANGELOG.md
    if not changes(version):
        problems.append("The section Unreleased of CHANGELOG.md is empty: describe the changes of the release")

    # The previous release, on Zenodo
    previous = None
    if release.get("kg_record"):
        latest = Zenodo(release["zenodo_url"]).latest(release["kg_record"])
        previous = {
            "version": latest["metadata"]["version"],
            "doi": latest["doi"],
            "id": latest["id"],
            "concept_doi": latest.get("conceptdoi"),
        }
        if semver_key(previous["version"]) and semver_key(previous["version"]) >= semver_key(version):
            problems.append(f"{version} is not after the latest release on Zenodo, {previous['version']}")
        concept_doi = latest.get("conceptdoi")
        record = cfg["metadata"].get("dumps_record") or ""
        if concept_doi and not record.endswith(concept_doi):
            problems.append(
                f"config.yaml metadata.dumps_record ({record}) is not the concept DOI of release.kg_record ({concept_doi})"
            )

    # The credentials
    try:
        zenodo = zenodo_client(cfg)
        zenodo.request("GET", "/deposit/depositions", params={"size": 1})
    except ReleaseError as error:
        problems.append(str(error))
    if release.get("github", True):
        if subprocess.run(["gh", "auth", "status"], capture_output=True).returncode != 0:
            problems.append("The GitHub CLI is not authenticated (gh auth login)")
        elif subprocess.run(["gh", "repo", "view", release["github_repo"]], capture_output=True).returncode != 0:
            problems.append(f"The GitHub CLI cannot see the repository {release['github_repo']}")

    if problems:
        raise ReleaseError("The release cannot start:\n- " + "\n- ".join(problems))
    result = {"version": version, "date": today(), "head": git("rev-parse", "HEAD"), "previous": previous}
    write_json(os.path.join(args.state, "checked.json"), result)
    log(f"Checked: release {version}, after {previous['version'] if previous else 'none'}")


def step_draft(args, cfg, state):
    release = cfg["release"]
    zenodo = zenodo_client(cfg)
    previous = state["checked"]["previous"]
    if "draft" in state:
        try:
            zenodo.deposition(state["draft"]["id"])
            log(f"Draft {state['draft']['draft_url']} exists: reused")
            return
        except ReleaseError:
            log(f"Draft {state['draft']['id']} not found on Zenodo: making a new one")
    if release.get("kg_record"):
        draft = zenodo.new_version(previous["id"], release["kg_record"])
    else:
        draft = zenodo.new_deposition()
    zenodo.delete_files(draft)
    state["draft"] = {}
    f = facts(args, cfg, state)
    result = zenodo.set_metadata(draft["id"], zenodo_metadata(cfg, f, reserve=True))
    doi = (result["metadata"].get("prereserve_doi") or {}).get("doi")
    if not doi:
        zenodo.delete(draft["id"])
        raise ReleaseError("Zenodo did not reserve a DOI for the draft (deleted)")
    result = {
        "id": draft["id"],
        "doi": doi,
        "url": f"{zenodo.url}/records/{draft['id']}",
        "draft_url": f"{zenodo.url}/uploads/{draft['id']}",
        "files_url": f"{zenodo.url}/records/{draft['id']}/files",
        "concept_doi": result.get("conceptdoi") or (previous or {}).get("concept_doi"),
    }
    if not result["concept_doi"] and release.get("kg_record"):
        result["concept_doi"] = cfg["metadata"]["dumps_record"].replace("https://doi.org/", "")
    write_json(os.path.join(args.state, "draft.json"), result)
    log(f"Draft {result['draft_url']}, DOI {doi}")


def update_changelog(version, date):
    with open(CHANGELOG) as f:
        text = f.read()
    if re.search(rf"^## \[?{re.escape(version)}\]?", text, flags=re.M):
        return
    text, n = re.subn(r"^## Unreleased[ \t]*$", f"## Unreleased\n\n## {version} - {date}", text, count=1, flags=re.M)
    if not n:
        raise ReleaseError("CHANGELOG.md has no section Unreleased")
    with open(CHANGELOG, "w") as f:
        f.write(text)


def update_citation(version, date):
    with open(CITATION) as f:
        text = f.read()
    text = re.sub(r"^version: .*$", f"version: {version}", text, flags=re.M)
    if re.search(r"^date-released: ", text, flags=re.M):
        text = re.sub(r"^date-released: .*$", f"date-released: '{date}'", text, flags=re.M)
    else:
        text = text.rstrip("\n") + f"\ndate-released: '{date}'\n"
    with open(CITATION, "w") as f:
        f.write(text)


def update_website(f):
    data = read_json(WEBSITE_DATA) if os.path.exists(WEBSITE_DATA) else {"releases": []}
    entry = {
        "version": f["version"],
        "date": f["date"],
        "doi": f["doi"],
        "tag": f"v{f['version']}",
        "triples": f["triples"],
        "triples_about": about_millions(f["triples"]),
        "graphs": f["graphs"],
        "figures": f["figures"],
        "sources": f["sources"],
        "validation": f["validation"],
        # The numbers as text (Liquid cannot format them)
        "formatted": {key: number(value) for key, value in dict(f["figures"], triples=f["triples"]).items()},
    }
    releases = [r for r in data["releases"] if r["version"] != f["version"]]
    data["releases"] = sorted([entry] + releases, key=lambda r: semver_key(r["version"]), reverse=True)
    data["concept_doi"] = f["concept_doi"] or data.get("concept_doi")
    data["current"] = data["releases"][0]
    write_json(WEBSITE_DATA, data)


def step_commit(args, cfg, state):
    version = args.version
    tag = f"v{version}"
    path = os.path.join(args.state, "commit.json")
    head_message = git("log", "-1", "--format=%s")
    if head_message != f"Release {version}":
        if git("rev-parse", "HEAD") != state["checked"]["head"]:
            raise ReleaseError("HEAD moved since the check: discard the release (rule release_discard) and start again")
        f = facts(args, cfg, state)
        date = state["checked"]["date"]
        update_changelog(version, date)
        f["changes"] = changes(version)
        update_citation(version, date)
        notes = NOTES.format(version=version)
        os.makedirs(os.path.dirname(notes), exist_ok=True)
        with open(notes, "w") as n:
            n.write(render(NOTES_TEMPLATE, f))
        update_website(f)
        git("add", CHANGELOG, CITATION, notes, WEBSITE_DATA)
        git("commit", "--quiet", "-m", f"Release {version}")
    if not git("rev-parse", "-q", "--verify", f"refs/tags/{tag}", check=False):
        git("tag", "-a", tag, "-m", f"Climate Change Knowledge Graph {version}")
    draft = state["draft"]
    previous = state["checked"]["previous"]
    result = {
        "commit": git("rev-parse", "HEAD"),
        "release": {
            "version": version,
            "doi": draft["doi"],
            "url": draft["url"],
            "date": state["checked"]["date"],
            "concept_doi": draft.get("concept_doi"),
            "files_url": draft["files_url"],
            "previous": {"version": previous["version"], "doi": previous["doi"]} if previous else None,
        },
    }
    write_json(path, result)
    log(f"Release commit {result['commit'][:7]}, tagged {tag} (not pushed)")


def step_upload(args, cfg, state):
    if git("rev-parse", "HEAD") != state["commit"]["commit"]:
        raise ReleaseError("HEAD is not the release commit")
    zenodo = zenodo_client(cfg)
    draft = zenodo.deposition(state["draft"]["id"])
    if draft.get("submitted"):
        raise ReleaseError("The draft is already published")
    local = {os.path.basename(path): md5(path) for path in (args.dump, args.void)}
    remote = {f.get("filename"): f.get("checksum", "").replace("md5:", "") for f in draft.get("files", [])}
    if "upload" in state and remote == local:
        zenodo.set_metadata(draft["id"], zenodo_metadata(cfg, facts(args, cfg, state)))
        log(f"Files already uploaded; metadata updated. The draft is ready to review: {state['draft']['draft_url']}")
        return
    zenodo.delete_files(draft)
    files = []
    for path in (args.dump, args.void):
        name = os.path.basename(path)
        local = md5(path)
        result = zenodo.upload(draft, path, name)
        remote = (result or {}).get("checksum", "").replace("md5:", "")
        if remote and remote != local:
            raise ReleaseError(f"Upload of {name}: checksum {remote} on Zenodo, {local} here")
        files.append({"name": name, "size": os.path.getsize(path), "md5": local})
        log(f"Uploaded {name} ({os.path.getsize(path):,} bytes, md5 {local})")
    zenodo.set_metadata(draft["id"], zenodo_metadata(cfg, facts(args, cfg, state)))
    write_json(os.path.join(args.state, "upload.json"), {"files": files})
    log(f"The draft is ready to review: {state['draft']['draft_url']}")


def step_github(args, cfg, state):
    release = cfg["release"]
    version = args.version
    tag = f"v{version}"
    result = {"workflow_doi": None, "pushed": False, "github_release": False}
    if release.get("push", True):
        commit = state["commit"]["commit"]
        git("fetch", "--quiet", release["remote"], release["branch"])
        merged = subprocess.run(
            ["git", "merge-base", "--is-ancestor", commit, f"{release['remote']}/{release['branch']}"]
        ).returncode == 0
        pushed = subprocess.run(
            ["true"] if merged else ["git", "push", release["remote"], f"{commit}:refs/heads/{release['branch']}"],
            capture_output=True,
            text=True,
        )
        if pushed.returncode != 0:
            raise ReleaseError(
                f"Could not push the release commit to {release['remote']}/{release['branch']}:\n{pushed.stderr}\n"
                "If the branch is protected, merge the release commit through a pull request (with a merge commit),"
                " then run the release again: it resumes from here."
            )
        git("push", release["remote"], f"refs/tags/{tag}")
        result["pushed"] = True
        log(f"Pushed the release commit{' (already in ' + release['branch'] + ')' if merged else ''} and the tag {tag}")
    if release.get("github", True):
        exists = subprocess.run(["gh", "release", "view", tag, "--repo", release["github_repo"]], capture_output=True)
        if exists.returncode != 0:
            run(
                "gh", "release", "create", tag, "--repo", release["github_repo"], "--verify-tag",
                "--title", f"Climate Change Knowledge Graph {version}",
                "--notes-file", NOTES.format(version=version),
            )
            log(f"GitHub release {tag} made")
        result["github_release"] = True
    if release.get("workflow_record"):
        zenodo = Zenodo(release["zenodo_url"])
        deadline = time.time() + 60 * float(release.get("workflow_doi_timeout", 30))
        log("Waiting for the Zenodo GitHub integration to archive the release")
        while True:
            for record in zenodo.versions(release["workflow_record"]):
                if record["metadata"].get("version") in (tag, version):
                    result["workflow_doi"] = record["doi"]
                    break
            if result["workflow_doi"] or time.time() > deadline:
                break
            time.sleep(30)
        if not result["workflow_doi"]:
            raise ReleaseError(
                f"No version {tag} of the workflow record {release['workflow_record']} on Zenodo yet: check that the"
                " GitHub integration of Zenodo is on for the repository, then run the release again"
            )
        log(f"Workflow archived: DOI {result['workflow_doi']}")
    write_json(os.path.join(args.state, "github.json"), result)


def step_publish(args, cfg, state):
    zenodo = zenodo_client(cfg)
    draft_id = state["draft"]["id"]
    deposition = zenodo.deposition(draft_id)
    if not deposition.get("submitted"):
        zenodo.set_metadata(draft_id, zenodo_metadata(cfg, facts(args, cfg, state)))
        deposition = zenodo.publish(draft_id)
    if deposition.get("doi") != state["draft"]["doi"]:
        raise ReleaseError(f"Published with DOI {deposition.get('doi')}, not the reserved {state['draft']['doi']}")
    published = {f["filename"] if "filename" in f else f["key"]: f.get("checksum", "") for f in deposition.get("files", [])}
    for file in state["upload"]["files"]:
        checksum = published.get(file["name"], "").replace("md5:", "")
        if checksum and checksum != file["md5"]:
            raise ReleaseError(f"{file['name']} on Zenodo has md5 {checksum}, not {file['md5']}")
    result = {"doi": deposition["doi"], "url": state["draft"]["url"], "date": state["checked"]["date"]}
    write_json(os.path.join(args.state, "publish.json"), result)
    log(f"Published the Climate Change Knowledge Graph {args.version}: https://doi.org/{result['doi']}")


def step_discard(args, cfg, state):
    release = cfg["release"]
    if "publish" in state and not release.get("sandbox"):
        raise ReleaseError("The release is published: it cannot be discarded")
    if state.get("github", {}).get("pushed") or state.get("github", {}).get("github_release"):
        raise ReleaseError("The release commit and tag are public (pushed): discard by hand")
    tag = f"v{args.version}"
    if "draft" in state and "publish" not in state:
        zenodo_client(cfg).delete(state["draft"]["id"])
        log(f"Deleted the draft {state['draft']['id']} on Zenodo")
    if git("rev-parse", "-q", "--verify", f"refs/tags/{tag}", check=False):
        remote_tag = git("ls-remote", "--tags", release["remote"], f"refs/tags/{tag}", check=False)
        if remote_tag:
            raise ReleaseError(f"The tag {tag} is on {release['remote']}: discard by hand")
        git("tag", "-d", tag)
        log(f"Deleted the tag {tag}")
    if git("log", "-1", "--format=%s") == f"Release {args.version}":
        git("reset", "--keep", "HEAD^")
        log("Removed the release commit")
    for step in ("publish", "github", "upload", "commit", "draft", "checked"):
        path = os.path.join(args.state, f"{step}.json")
        if os.path.exists(path):
            os.remove(path)
    log("Discarded: the next build describes itself as a build, not a release")


STEPS = {
    "check": step_check,
    "draft": step_draft,
    "commit": step_commit,
    "upload": step_upload,
    "github": step_github,
    "publish": step_publish,
    "discard": step_discard,
}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("step", choices=STEPS)
    parser.add_argument("--version", required=True)
    parser.add_argument("--config", required=True, help="the configuration of the workflow, as JSON")
    parser.add_argument("--state", required=True, help="the state directory of the release")
    parser.add_argument("--statistics", default="kg/metadata/statistics.ttl")
    parser.add_argument("--figures", default="kg/metadata/figures.json")
    parser.add_argument("--validation", default="kg/validation/summary.json")
    parser.add_argument("--shapes", default="kg/validation/shapes.ttl")
    parser.add_argument("--dump", default="kg/export/kg.nq.gz")
    parser.add_argument("--void", default="kg/export/void.ttl")
    parser.add_argument("--cmor-previous-editions", type=int, default=0)
    args = parser.parse_args(argv)
    with open(args.config) as c:
        cfg = json.load(c)
    try:
        STEPS[args.step](args, cfg, load_state(args))
    except ReleaseError as error:
        log(f"ERROR: {error}")
        sys.exit(1)


if __name__ == "__main__":
    main()
