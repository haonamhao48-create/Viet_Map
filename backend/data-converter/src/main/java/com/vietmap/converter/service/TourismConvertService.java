package com.vietmap.converter.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vietmap.converter.config.ConverterProperties;
import com.vietmap.converter.model.ConvertResult;
import com.vietmap.converter.util.JsonSanitizer;
import com.vietmap.converter.util.ProjectPaths;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Iterator;
import java.util.Map;

@Service
public class TourismConvertService {

    private final ConverterProperties properties;
    private final ProjectPaths projectPaths;

    public TourismConvertService(ConverterProperties properties, ProjectPaths projectPaths) {
        this.properties = properties;
        this.projectPaths = projectPaths;
    }

    public ConvertResult.FileStats convertTourism() throws IOException {
        Path source = projectPaths.resolve(properties.getSources().getTourism());
        Path target = projectPaths.resolve(properties.getOutputs().getTourism());

        JsonNode root = JsonSanitizer.readTree(source);
        if (!root.isArray()) {
            throw new IllegalStateException("Tourism source must be a JSON array.");
        }

        ArrayNode output = JsonSanitizer.arrayNode();
        int id = 1;

        for (JsonNode item : root) {
            if (!item.isObject()) {
                continue;
            }
            ObjectNode normalized = normalizeDestination((ObjectNode) item, id++);
            output.add(normalized);
        }

        backupIfNeeded(target);
        JsonSanitizer.writeCompact(target, output);

        return new ConvertResult.FileStats(
                "tourism_destinations",
                projectPaths.projectRoot().relativize(target.toAbsolutePath()).toString().replace('\\', '/'),
                Files.size(source),
                Files.size(target),
                output.size(),
                0,
                0
        );
    }

    private ObjectNode normalizeDestination(ObjectNode source, int fallbackId) {
        ObjectNode target = JsonSanitizer.objectNode();

        int resolvedId = source.path("id").asInt(fallbackId);
        target.put("id", resolvedId);
        target.put("name", text(source, "name"));
        target.put("province", text(source, "province"));
        target.put("description", text(source, "description"));
        target.put("latitude", number(source, "latitude"));
        target.put("longitude", number(source, "longitude"));

        ArrayNode keywords = JsonSanitizer.arrayNode();
        JsonNode sourceKeywords = source.get("keywords");
        if (sourceKeywords != null && sourceKeywords.isArray()) {
            for (JsonNode keyword : sourceKeywords) {
                String value = keyword.asText("").trim();
                if (!value.isEmpty()) {
                    keywords.add(value);
                }
            }
        }
        target.set("keywords", keywords);

        Iterator<Map.Entry<String, JsonNode>> extraFields = source.fields();
        while (extraFields.hasNext()) {
            Map.Entry<String, JsonNode> entry = extraFields.next();
            String key = entry.getKey();
            if (target.has(key)) {
                continue;
            }
            target.set(key, entry.getValue());
        }

        return target;
    }

    private String text(ObjectNode node, String field) {
        return node.path(field).asText("").trim();
    }

    private double number(ObjectNode node, String field) {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            return 0.0;
        }
        if (value.isNumber()) {
            double parsed = value.asDouble();
            return Double.isFinite(parsed) ? parsed : 0.0;
        }
        try {
            return Double.parseDouble(value.asText("0"));
        } catch (NumberFormatException ex) {
            return 0.0;
        }
    }

    private void backupIfNeeded(Path target) throws IOException {
        if (!properties.isBackupBeforeWrite() || !Files.exists(target)) {
            return;
        }
        Path backupDir = target.getParent().resolve("_backup");
        Files.createDirectories(backupDir);
        Path backupFile = backupDir.resolve(target.getFileName().toString() + ".bak");
        Files.copy(target, backupFile, StandardCopyOption.REPLACE_EXISTING);
    }
}
