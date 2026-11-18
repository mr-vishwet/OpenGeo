from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from opengeo.api.app import create_app
from opengeo.api.dataset import GeoJsonFeatureStore, load_default_store

SQUARE = {
    "type": "Polygon",
    "coordinates": [
        [
            [73.85, 18.52],
            [73.86, 18.52],
            [73.86, 18.53],
            [73.85, 18.53],
            [73.85, 18.52],
        ]
    ],
}


@pytest.fixture()
def client() -> Iterator[TestClient]:
    app = create_app(store_factory=load_default_store)
    with TestClient(app) as test_client:
        yield test_client


def test_health_does_not_touch_the_dataset(client: TestClient):
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_reports_missing_index_and_database(client: TestClient):
    body = client.get("/readyz").json()
    assert body["status"] == "ready"
    assert body["checks"]["spatial_index"] == "not_configured"
    assert body["checks"]["database"] == "not_attached"


def test_every_implemented_capability_has_a_route(client: TestClient):
    routes = {
        "spatial.distance": "/v1/spatial/distance",
        "spatial.contains": "/v1/spatial/contains",
        "spatial.covers": "/v1/spatial/contains",
        "spatial.intersects": "/v1/spatial/intersects",
        "nearby": "/v1/nearby",
        "places.get": "/v1/places/{feature_id}",
    }
    manifest = client.get("/v1/capabilities").json()
    implemented = {
        capability["name"]
        for capability in manifest["capabilities"]
        if capability["state"] == "implemented"
    }
    assert implemented == set(routes)
    served = {route.path for route in client.app.routes}
    assert set(routes.values()) <= served


def test_every_response_carries_a_request_id_header(client: TestClient):
    response = client.get("/v1/datasets")
    assert response.headers["X-Request-Id"]
    assert response.json()["meta"]["request_id"] == response.headers["X-Request-Id"]


def test_a_caller_supplied_request_id_is_echoed(client: TestClient):
    response = client.get("/v1/datasets", headers={"x-request-id": "ci-run-42.abc"})
    assert response.headers["X-Request-Id"] == "ci-run-42.abc"
    assert response.json()["meta"]["request_id"] == "ci-run-42.abc"


def test_a_request_id_that_could_inject_into_a_log_is_replaced(client: TestClient):
    response = client.get("/v1/datasets", headers={"x-request-id": "abc\nforged line"})
    assert response.headers["X-Request-Id"] != "abc\nforged line"
    assert len(response.headers["X-Request-Id"]) == 32


def test_envelope_has_the_documented_members(client: TestClient):
    body = client.get("/v1/datasets").json()
    assert set(body) == {"data", "meta", "provenance", "warnings"}
    assert body["meta"]["api_version"] == "v1"
    assert body["meta"]["dataset_version"].startswith("fixture-")
    assert body["provenance"]["sources"][0]["license"] == "Apache-2.0"


def test_capabilities_are_honest_about_what_is_missing(client: TestClient):
    manifest = client.get("/v1/capabilities").json()
    states = {entry["name"]: entry["state"] for entry in manifest["capabilities"]}
    assert states["spatial.distance"] == "implemented"
    assert states["nearby"] == "implemented"
    assert states["postgis"] == "unavailable"
    assert states["geocoding"] == "unavailable"
    assert states["routing"] == "requires_external_provider"
    assert manifest["offline_support"] is False
    assert manifest["coordinate_systems"] == ["EPSG:4326"]
    assert any("synthetic" in warning for warning in manifest["warnings"])


def test_nearby_returns_nearest_first_with_metres(client: TestClient):
    response = client.post(
        "/v1/nearby",
        json={
            "center": {"longitude": 73.8794, "latitude": 18.5158},
            "radius": {"value": 2, "unit": "km"},
            "categories": ["cafe"],
            "limit": 5,
        },
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data, "expected at least one cafe within 2 km"
    distances = [place["distance_m"] for place in data]
    assert distances == sorted(distances)
    assert all(place["category"] == "cafe" for place in data)
    assert all(place["dataset_version"].startswith("fixture-") for place in data)


def test_nearby_rejects_a_radius_over_the_documented_maximum(client: TestClient):
    response = client.post(
        "/v1/nearby",
        json={
            "center": {"longitude": 73.8794, "latitude": 18.5158},
            "radius": {"value": 500, "unit": "km"},
        },
    )
    assert response.status_code == 422
    error = response.json()["errors"][0]
    assert error["code"] == "invalid_input"
    assert error["field"] == "radius"


def test_nearby_rejects_a_latitude_that_signals_a_swapped_pair(client: TestClient):
    response = client.post(
        "/v1/nearby",
        json={
            "center": {"longitude": 73.8, "latitude": 118.5},
            "radius": {"value": 1, "unit": "km"},
        },
    )
    assert response.status_code == 422
    assert response.json()["errors"][0]["code"] == "invalid_input"


def test_place_with_no_name_returns_null_rather_than_an_invented_label(client: TestClient):
    body = client.get("/v1/places/opengeo:fixture:place:0011").json()
    assert body["data"]["name"] is None
    assert body["data"]["distance_m"] is None


def test_distance_reports_a_method_and_a_unit(client: TestClient):
    body = client.post(
        "/v1/spatial/distance",
        json={
            "origin": {"longitude": 73.8567, "latitude": 18.5204},
            "destination": {"longitude": 72.8777, "latitude": 19.076},
            "unit": "km",
        },
    ).json()
    assert body["data"]["method"] == "geodesic"
    assert body["data"]["unit"] == "km"
    assert 115 < body["data"]["value"] < 125


def test_network_distance_is_refused_rather_than_faked(client: TestClient):
    response = client.post(
        "/v1/spatial/distance",
        json={
            "origin": {"longitude": 73.8567, "latitude": 18.5204},
            "destination": {"longitude": 72.8777, "latitude": 19.076},
            "method": "network_travel",
        },
    )
    assert response.status_code == 400
    assert response.json()["errors"][0]["code"] == "unsupported_capability"


def test_contains_excludes_a_boundary_point(client: TestClient):
    body = client.post(
        "/v1/spatial/contains",
        json={
            "container": SQUARE,
            "candidate_position": {"longitude": 73.85, "latitude": 18.52},
            "boundary_rule": "contains",
        },
    ).json()
    assert body["data"]["result"] is False


def test_covers_includes_a_boundary_point(client: TestClient):
    body = client.post(
        "/v1/spatial/contains",
        json={
            "container": SQUARE,
            "candidate_position": {"longitude": 73.85, "latitude": 18.52},
            "boundary_rule": "covers",
        },
    ).json()
    assert body["data"]["result"] is True


def test_contains_accepts_a_feature_reference(client: TestClient):
    store = load_default_store()
    polygon_id = next(
        feature.id for feature in store.features() if feature.geometry.geom_type == "Polygon"
    )
    response = client.post(
        "/v1/spatial/contains",
        json={
            "container_feature_id": polygon_id,
            "candidate_position": {"longitude": 73.855, "latitude": 18.525},
        },
    )
    assert response.status_code == 200


def test_contains_rejects_an_open_ring_with_a_stable_code(client: TestClient):
    broken = {"type": "Polygon", "coordinates": [SQUARE["coordinates"][0][:-1]]}
    response = client.post(
        "/v1/spatial/contains",
        json={
            "container": broken,
            "candidate_position": {"longitude": 73.855, "latitude": 18.525},
        },
    )
    assert response.status_code == 422
    assert response.json()["errors"][0]["code"] == "invalid_input"
    assert response.json()["errors"][0]["details"] == {"geometry_code": "invalid_ring"}


def test_intersects_detects_a_crossing_line(client: TestClient):
    body = client.post(
        "/v1/spatial/intersects",
        json={
            "container": SQUARE,
            "candidate": {
                "type": "LineString",
                "coordinates": [[73.84, 18.525], [73.87, 18.525]],
            },
        },
    ).json()
    assert body["data"]["result"] is True


def test_missing_place_returns_not_found_with_a_code(client: TestClient):
    response = client.get("/v1/places/opengeo:does-not-exist")
    assert response.status_code == 404
    assert response.json()["errors"][0]["code"] == "not_found"


def test_fixture_store_is_validated_on_load():
    store = GeoJsonFeatureStore()
    assert len(store.features()) == 13
    assert store.dataset_version.startswith("fixture-")


def test_openapi_document_is_generated_from_the_implementation(client: TestClient):
    schema = client.get("/openapi.json").json()
    assert "/v1/nearby" in schema["paths"]
    assert "/v1/spatial/contains" in schema["paths"]
    radius_unit = schema["components"]["schemas"]["Radius"]["properties"]["unit"]
    resolved = schema["components"]["schemas"]["DistanceUnit"]["enum"]
    assert radius_unit.get("$ref", "").endswith("DistanceUnit") or "enum" in radius_unit
    assert "m" in resolved
