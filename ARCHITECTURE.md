# ERI (Emergency Response Intelligence) - Architecture

ERI is built to solve CIC26 Problem Statement #18: "The Ambulance That Couldn't Wait." It is an adaptive, real-time routing and dispatch system designed to navigate complex urban environments during critical emergencies.

## Core Technologies

*   **Frontend**: Flutter (Web focus)
*   **State Management**: Riverpod (Reactive, reactive data streams)
*   **Backend & Data**: Firebase (Firestore for real-time synchronization)
*   **Routing Engine**: OSRM (Open Source Routing Machine) via Public API
*   **Mapping**: `flutter_map` with `latlong2`

## Architecture Overview

ERI operates on a reactive loop where changing conditions automatically cascade through the system to update routing decisions.

### 1. Data Ingestion (Firebase)
*   **`hospitalsStreamProvider`**: Listens to real-time hospital capacities, loads, and available specialties.
*   **`roadConditionsStreamProvider`**: Listens to live traffic incidents (e.g., construction, blockages).

### 2. State & Computation (Riverpod)
*   **`SimulationProvider`**: Exposes "Ops Control" actions that allow judges to artificially spike hospital loads or block roads. This directly writes to Firestore, which then pushes updates to all clients.
*   **`IncidentProvider` & `SecondaryIncidentProvider`**: Stores the location and type of current emergencies.
*   **`RoutingProvider`**: The central orchestrator. It watches the data streams (`incident`, `hospitals`, `conditions`) and automatically re-triggers `computeRoutes()` when any parameter changes.

### 3. The Scoring Engine (`ScoringEngine`)
Hospitals are evaluated based on a multi-factor formula (spec §3.2):
```
Score = (0.5 * ETA_Score) + (0.3 * Specialty_Score) + (0.2 * Capacity_Score)
```
*   **ETA (50%)**: Inverse of travel minutes.
*   **Specialty (30%)**: Binary match based on hospital capabilities.
*   **Capacity (20%)**: Derived from real-time hospital load (`1.0 - load/100`).

### 4. Routing & Resilience (`OsrmService`)
*   **Primary Path**: Requests multi-point ETA matrices from OSRM to find the fastest hospitals, then requests the full polyline route for the top candidate.
*   **Resilience (Fallback)**: If the OSRM service is rate-limited or fails (simulated via the "Network Resilience" toggle), the system gracefully degrades. It falls back to straight-line distance calculations (Haversine formula via `latlong2`) and assumes an average speed to estimate ETA, ensuring dispatch is never fully offline.
*   **Live Re-Routing**: If a route is updated while the ambulance is in transit, a reactive listener in the map panel detects the change and visually alerts the user with a "Rerouting..." overlay.

### 5. Multi-Incident Handling
The system handles multiple simultaneous incidents (e.g., Rush Hour scenarios). When a primary incident is dispatched to Hospital A, the routing engine artificially inflates Hospital A's load before computing the secondary incident. This prevents double-booking a single hospital's capacity during mass casualty or high-volume events.

## Hackathon Constraints Met

1.  **Fastest Route via Live Traffic**: Achieved by passing `roadConditions` as exclude polygons/nodes to the routing service, automatically penalizing congested roads.
2.  **Recommend Hospital via Capacity & Type**: Evaluated dynamically by the `ScoringEngine` using live Firestore data.
3.  **Continuous Adaptation**: Built natively into the architecture via Riverpod `ref.listen` hooks. Any change in Firestore immediately triggers a re-route.
