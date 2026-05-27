package com.vietmap.converter.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vietmap.converter.util.JsonSanitizer;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.io.geojson.GeoJsonReader;
import org.locationtech.jts.io.geojson.GeoJsonWriter;
import org.locationtech.jts.simplify.DouglasPeuckerSimplifier;

import java.util.Locale;

public class GeometryOptimizer {

    private static final GeoJsonReader GEO_JSON_READER = new GeoJsonReader();
    private static final GeoJsonWriter GEO_JSON_WRITER = new GeoJsonWriter();

    private final double simplifyTolerance;
    private final int coordinatePrecision;

    public GeometryOptimizer(double simplifyTolerance, int coordinatePrecision) {
        this.simplifyTolerance = simplifyTolerance;
        this.coordinatePrecision = coordinatePrecision;
    }

    public long countVertices(JsonNode geometry) {
        JsonNode coordinates = geometry.get("coordinates");
        if (coordinates == null || coordinates.isNull()) {
            return 0;
        }
        return countCoordinatePoints(coordinates);
    }

    public ObjectNode optimizeGeometry(JsonNode geometryNode) {
        if (geometryNode == null || geometryNode.isNull()) {
            return JsonSanitizer.objectNode();
        }

        try {
            Geometry geometry = GEO_JSON_READER.read(geometryNode.toString());
            if (geometry == null || geometry.isEmpty()) {
                return copyGeometryNode(geometryNode);
            }

            Geometry simplified = DouglasPeuckerSimplifier.simplify(geometry, simplifyTolerance);
            simplified = roundGeometry(simplified);

            String geoJson = GEO_JSON_WRITER.write(simplified);
            return (ObjectNode) JsonSanitizer.mapper().readTree(geoJson);
        } catch (Exception ex) {
            return roundCoordinatesOnly(copyGeometryNode(geometryNode));
        }
    }

    private ObjectNode copyGeometryNode(JsonNode geometryNode) {
        return geometryNode.deepCopy();
    }

    private ObjectNode roundCoordinatesOnly(ObjectNode geometryNode) {
        JsonNode coordinates = geometryNode.get("coordinates");
        if (coordinates != null && coordinates.isArray()) {
            geometryNode.set("coordinates", roundCoordinateArray((ArrayNode) coordinates, 0));
        }
        return geometryNode;
    }

    private Geometry roundGeometry(Geometry geometry) {
        if (geometry instanceof Point point) {
            return roundPoint(point);
        }
        if (geometry instanceof LineString lineString) {
            return roundLineString(lineString);
        }
        if (geometry instanceof LinearRing linearRing) {
            return roundLinearRing(linearRing);
        }
        if (geometry instanceof Polygon polygon) {
            return roundPolygon(polygon);
        }
        if (geometry instanceof MultiPolygon multiPolygon) {
            Polygon[] polygons = new Polygon[multiPolygon.getNumGeometries()];
            for (int i = 0; i < multiPolygon.getNumGeometries(); i++) {
                polygons[i] = roundPolygon((Polygon) multiPolygon.getGeometryN(i));
            }
            return multiPolygon.getFactory().createMultiPolygon(polygons);
        }
        if (geometry instanceof GeometryCollection collection) {
            Geometry[] parts = new Geometry[collection.getNumGeometries()];
            for (int i = 0; i < collection.getNumGeometries(); i++) {
                parts[i] = roundGeometry(collection.getGeometryN(i));
            }
            return collection.getFactory().createGeometryCollection(parts);
        }
        return geometry;
    }

    private Point roundPoint(Point point) {
        Coordinate coordinate = roundCoordinate(point.getCoordinate());
        return point.getFactory().createPoint(coordinate);
    }

    private LineString roundLineString(LineString lineString) {
        Coordinate[] coordinates = roundCoordinates(lineString.getCoordinates());
        return lineString.getFactory().createLineString(coordinates);
    }

    private LinearRing roundLinearRing(LinearRing linearRing) {
        Coordinate[] coordinates = roundCoordinates(linearRing.getCoordinates());
        return linearRing.getFactory().createLinearRing(coordinates);
    }

    private Polygon roundPolygon(Polygon polygon) {
        LinearRing shell = roundLinearRing((LinearRing) polygon.getExteriorRing());
        LinearRing[] holes = new LinearRing[polygon.getNumInteriorRing()];
        for (int i = 0; i < polygon.getNumInteriorRing(); i++) {
            holes[i] = roundLinearRing((LinearRing) polygon.getInteriorRingN(i));
        }
        return polygon.getFactory().createPolygon(shell, holes);
    }

    private Coordinate[] roundCoordinates(Coordinate[] source) {
        Coordinate[] result = new Coordinate[source.length];
        for (int i = 0; i < source.length; i++) {
            result[i] = roundCoordinate(source[i]);
        }
        return result;
    }

    private Coordinate roundCoordinate(Coordinate coordinate) {
        double x = round(coordinate.x);
        double y = round(coordinate.y);
        if (Double.isNaN(x) || Double.isNaN(y)) {
            return new Coordinate();
        }
        if (coordinate.getZ() == Coordinate.NULL_ORDINATE) {
            return new Coordinate(x, y);
        }
        return new Coordinate(x, y, round(coordinate.getZ()));
    }

    private double round(double value) {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            return Double.NaN;
        }
        double factor = Math.pow(10, coordinatePrecision);
        return Math.round(value * factor) / factor;
    }

    private ArrayNode roundCoordinateArray(ArrayNode coordinates, int depth) {
        ArrayNode result = JsonSanitizer.arrayNode();
        for (JsonNode child : coordinates) {
            if (depth >= 2 && child.isNumber()) {
                result.add(round(child.asDouble()));
            } else if (child.isArray()) {
                result.add(roundCoordinateArray((ArrayNode) child, depth + 1));
            } else {
                result.add(child);
            }
        }
        return result;
    }

    private long countCoordinatePoints(JsonNode node) {
        if (node == null || node.isNull()) {
            return 0;
        }
        if (node.isArray() && !node.isEmpty() && node.get(0).isNumber()) {
            return 1;
        }
        long total = 0;
        for (JsonNode child : node) {
            total += countCoordinatePoints(child);
        }
        return total;
    }

    @SuppressWarnings("unused")
    private String precisionSummary() {
        return String.format(Locale.ROOT, "tolerance=%.6f,precision=%d", simplifyTolerance, coordinatePrecision);
    }
}
