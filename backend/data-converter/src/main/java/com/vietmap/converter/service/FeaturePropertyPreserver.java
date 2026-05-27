package com.vietmap.converter.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vietmap.converter.util.JsonSanitizer;

import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Giữ đủ field mà Flutter FE đang đọc, đồng thời giữ các field phụ từ dataset gốc.
 */
public final class FeaturePropertyPreserver {

    private static final Set<String> PROVINCE_REQUIRED = Set.of(
            "id", "ten", "type", "ten_short", "shapeName", "macro_region",
            "area_km2", "population", "density", "centroid_lon", "centroid_lat",
            "capital", "predecessors", "is_archipelago", "ma", "parent_ma", "parent_ten", "decree"
    );

    private static final Set<String> COMMUNE_REQUIRED = Set.of(
            "id", "ma", "ten", "type", "parent_ma", "parent_ten", "macro_region",
            "area_km2", "population", "density", "capital", "predecessors", "decree"
    );

    private FeaturePropertyPreserver() {
    }

    public static ObjectNode preserveProvinceProperties(JsonNode source) {
        return preserve(source, PROVINCE_REQUIRED);
    }

    public static ObjectNode preserveCommuneProperties(JsonNode source) {
        return preserve(source, COMMUNE_REQUIRED);
    }

    private static ObjectNode preserve(JsonNode source, Set<String> requiredKeys) {
        ObjectNode target = JsonSanitizer.objectNode();
        if (source == null || !source.isObject()) {
            ensureDefaults(target, requiredKeys);
            return target;
        }

        Iterator<Map.Entry<String, JsonNode>> fields = source.fields();
        while (fields.hasNext()) {
            Map.Entry<String, JsonNode> entry = fields.next();
            target.set(entry.getKey(), normalizeValue(entry.getValue()));
        }

        ensureDefaults(target, requiredKeys);
        return target;
    }

    private static void ensureDefaults(ObjectNode target, Set<String> requiredKeys) {
        for (String key : requiredKeys) {
            if (!target.has(key) || target.get(key).isNull()) {
                switch (key) {
                    case "area_km2", "density", "centroid_lon", "centroid_lat" -> target.put(key, 0.0);
                    case "population" -> target.put(key, 0);
                    case "is_archipelago" -> target.put(key, false);
                    default -> target.put(key, "");
                }
            }
        }
    }

    private static JsonNode normalizeValue(JsonNode value) {
        if (value == null || value.isNull()) {
            return JsonSanitizer.mapper().nullNode();
        }
        if (value.isFloatingPointNumber()) {
            double number = value.asDouble();
            if (Double.isNaN(number) || Double.isInfinite(number)) {
                return JsonSanitizer.mapper().nullNode();
            }
        }
        if (value.isTextual()) {
            String text = value.asText();
            if ("NaN".equalsIgnoreCase(text) || "null".equalsIgnoreCase(text)) {
                return JsonSanitizer.mapper().nullNode();
            }
        }
        return value;
    }

    public static List<String> sortedKeys(ObjectNode properties) {
        LinkedHashSet<String> keys = new LinkedHashSet<>();
        properties.fieldNames().forEachRemaining(keys::add);
        return keys.stream().sorted().toList();
    }
}
