# Benchmarks

`run_baseline.py` measures the parts of OpenGeo that exist today and refuses to
imply anything about the parts that do not: the fixture store has no spatial
index and there is no database behind these numbers.

```bash
python benchmarks/run_baseline.py --iterations 300 --out results/<date>-<host>.json
```

Every report records the commit, dependency versions, dataset version, feature
count and hardware it came from. A number without that context is not a
benchmark, and numbers from different hosts are not comparable.

`results/2026-11-19-dev-laptop.json` is this laptop, recorded before any
PostGIS or routing work. It is a baseline to beat, not a service-level
guarantee.
