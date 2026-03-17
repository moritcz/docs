import logging
from datetime import datetime
from typing import Any

import aiohttp

from config import GIS_API_KEY

log = logging.getLogger(__name__)

GEOCODE_URL = "https://catalog.api.2gis.com/3.0/items/geocode"
ROUTING_URL = "https://routing.api.2gis.com/public_transport/2.0"


async def geocode(address: str) -> tuple[float, float] | None:
    """Convert a text address to (lat, lon). Returns None if not found."""
    params = {
        "q": address,
        "fields": "items.point",
        "key": GIS_API_KEY,
        "locale": "ru_KZ",
        "region_id": "149",  # Almaty region in 2GIS
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(GEOCODE_URL, params=params, timeout=aiohttp.ClientTimeout(total=10)) as resp:
                data = await resp.json()
        items = data.get("result", {}).get("items", [])
        if not items:
            return None
        point = items[0].get("point", {})
        lat, lon = point.get("lat"), point.get("lon")
        if lat is None or lon is None:
            return None
        return float(lat), float(lon)
    except Exception as e:
        log.error("geocode error: %s", e)
        return None


async def get_transit_routes(
    from_lat: float,
    from_lon: float,
    to_lat: float,
    to_lon: float,
    departure_time: datetime | None = None,
) -> list[dict[str, Any]]:
    """
    Fetch public transit routes from 2GIS between two coordinates.

    Returns a sorted list of route dicts:
      {
        "route_names": ["38"],
        "total_time": 25,       # minutes
        "transfers": 0,
        "first_stop": "ул. Абая",
        "arrival_minutes": 7,   # minutes until first bus departs
      }
    """
    if departure_time is None:
        departure_time = datetime.now()

    payload = {
        "source": {"lat": from_lat, "lon": from_lon},
        "target": {"lat": to_lat, "lon": to_lon},
        "start_time": departure_time.strftime("%Y-%m-%dT%H:%M:%S"),
        "transport": ["bus", "trolleybus", "tram", "minibus"],
    }

    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                ROUTING_URL,
                params={"key": GIS_API_KEY},
                json=payload,
                timeout=aiohttp.ClientTimeout(total=15),
            ) as resp:
                data = await resp.json()
    except Exception as e:
        log.error("routing error: %s", e)
        return []

    return _parse_routes(data, departure_time)


def _parse_routes(data: dict, departure_time: datetime) -> list[dict]:
    routes = []
    now = departure_time

    for route in data.get("result", []):
        legs = route.get("legs", [])
        transit_legs = [leg for leg in legs if leg.get("type") == "transit"]
        if not transit_legs:
            continue

        route_names: list[str] = []
        first_stop: str | None = None
        arrival_minutes: int | None = None

        for i, leg in enumerate(transit_legs):
            name = leg.get("route", {}).get("name") or leg.get("route", {}).get("number", "?")
            route_names.append(str(name))

            if i == 0:
                stops = leg.get("stops", [])
                if stops:
                    first_stop = stops[0].get("name")
                dep_time_str = leg.get("departure_time") or leg.get("start_time")
                if dep_time_str:
                    try:
                        dep_dt = datetime.fromisoformat(dep_time_str.replace("Z", "+00:00"))
                        # Make both naive for comparison
                        dep_naive = dep_dt.replace(tzinfo=None)
                        diff = int((dep_naive - now).total_seconds() / 60)
                        arrival_minutes = max(0, diff)
                    except ValueError:
                        pass

        total_seconds = route.get("duration", 0)
        total_time = max(1, total_seconds // 60)
        transfers = len(transit_legs) - 1

        routes.append({
            "route_names": route_names,
            "total_time": total_time,
            "transfers": transfers,
            "first_stop": first_stop,
            "arrival_minutes": arrival_minutes,
        })

    # Sort: prioritise routes with known arrival time and soonest departure
    routes.sort(key=lambda r: (
        r["arrival_minutes"] is None,
        r["arrival_minutes"] if r["arrival_minutes"] is not None else 9999,
        r["total_time"],
    ))
    return routes[:5]
