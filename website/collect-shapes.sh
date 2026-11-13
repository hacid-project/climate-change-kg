#!/bin/sh
# Copies the SHACL shapes (shapes/*.ttl) into the website, where Jekyll
# publishes them as static files at <site>/shapes/ (together with the landing
# page, shapes.md), and writes the combined file shapes.ttl. Turtle files can be
# concatenated (the @prefix directives may be repeated).
set -e
cd "$(dirname "$0")/.."
mkdir -p website/shapes
cp shapes/*.ttl website/shapes/
cat shapes/*.ttl > website/shapes/shapes.ttl
