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
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class GeoJsonConvertService {

    private final ConverterProperties properties;
    private final ProjectPaths projectPaths;

    public GeoJsonConvertService(ConverterProperties properties, ProjectPaths projectPaths) {
        this.properties = properties;
        this.projectPaths = projectPaths;
    }

    public ConvertResult.FileStats convertVietnamComplete() throws IOException {
        Path source = projectPaths.resolve(properties.getSources().getVietnamComplete());
        Path target = projectPaths.resolve(properties.getOutputs().getVietnamComplete());
        return convertFeatureCollection(
                "vietnam_complete",
                source,
                target,
                FeaturePropertyPreserver::preserveProvinceProperties
        );
    }

    public ConvertResult.FileStats convertCommunesWithSplit() throws IOException {
        Path source = projectPaths.resolve(properties.getSources().getCommunes());
        Path mergedTarget = projectPaths.resolve(properties.getOutputs().getCommunesMerged());
        Path splitDir = projectPaths.resolve(properties.getOutputs().getSplitCommunesDir());
        Path manifestPath = projectPaths.resolve(properties.getOutputs().getSplitManifest());

        JsonNode root = JsonSanitizer.readTree(source);
        ArrayNode features = (ArrayNode) root.get("features");

        GeometryOptimizer optimizer = createOptimizer();
        Map<String, List<ObjectNode>> byProvince = new LinkedHashMap<>();
        ArrayNode mergedFeatures = JsonSanitizer.arrayNode();

        long verticesBefore = 0;
        long verticesAfter = 0;

        for (JsonNode featureNode : features) {
            ObjectNode feature = (ObjectNode) featureNode;
            JsonNode geometry = feature.get("geometry");
            verticesBefore += optimizer.countVertices(geometry);

            ObjectNode converted = buildFeature(
                    feature.get("properties"),
                    geometry,
                    optimizer,
                    FeaturePropertyPreserver::preserveCommuneProperties
            );
            verticesAfter += optimizer.countVertices(converted.get("geometry"));
            mergedFeatures.add(converted);

            String provinceCode = provinceCode(converted.get("properties"));
            byProvince.computeIfAbsent(provinceCode, key -> new ArrayList<>()).add(converted.deepCopy());
        }

        ObjectNode mergedRoot = buildFeatureCollection(mergedFeatures);
        writeOutput(mergedTarget, mergedRoot);

        Files.createDirectories(splitDir);
        List<ObjectNode> manifestEntries = new ArrayList<>();

        List<Map.Entry<String, List<ObjectNode>>> sortedProvinces = byProvince.entrySet().stream()
                .sorted(Comparator.comparing(Map.Entry::getKey))
                .toList();

        for (Map.Entry<String, List<ObjectNode>> entry : sortedProvinces) {
            String provinceCode = entry.getKey();
            ArrayNode provinceFeatures = JsonSanitizer.arrayNode();
            entry.getValue().forEach(provinceFeatures::add);

            ObjectNode provinceCollection = buildFeatureCollection(provinceFeatures);
            Path provinceFile = splitDir.resolve(provinceCode + ".geojson");
            writeOutput(provinceFile, provinceCollection);

            ObjectNode manifestItem = JsonSanitizer.objectNode();
            JsonNode sampleProps = entry.getValue().get(0).get("properties");
            manifestItem.put("provinceMa", provinceCode);
            manifestItem.put("parentTen", sampleProps.path("parent_ten").asText(""));
            manifestItem.put("featureCount", entry.getValue().size());
            manifestItem.put("file", toProjectRelative(provinceFile));
            manifestItem.put("bytes", Files.size(provinceFile));
            manifestEntries.add(manifestItem);
        }

        ObjectNode manifest = JsonSanitizer.objectNode();
        manifest.put("generatedAt", Instant.now().toString());
        manifest.put("source", toProjectRelative(source));
        manifest.put("mergedOutput", toProjectRelative(mergedTarget));
        manifest.put("featureCount", mergedFeatures.size());
        ArrayNode provinces = JsonSanitizer.arrayNode();
        manifestEntries.forEach(provinces::add);
        manifest.set("provinces", provinces);
        writeOutput(manifestPath, manifest);

        return new ConvertResult.FileStats(
                "communes_with_split",
                toProjectRelative(mergedTarget),
                Files.size(source),
                Files.size(mergedTarget),
                mergedFeatures.size(),
                verticesBefore,
                verticesAfter
        );
    }

    private ConvertResult.FileStats convertFeatureCollection(
            String name,
            Path source,
            Path target,
            java.util.function.Function<JsonNode, ObjectNode> propertyPreserver
    ) throws IOException {
        JsonNode root = JsonSanitizer.readTree(source);
        ArrayNode features = (ArrayNode) root.get("features");
        GeometryOptimizer optimizer = createOptimizer();

        long verticesBefore = 0;
        long verticesAfter = 0;
        ArrayNode convertedFeatures = JsonSanitizer.arrayNode();

        for (JsonNode featureNode : features) {
            ObjectNode feature = (ObjectNode) featureNode;
            JsonNode geometry = feature.get("geometry");
            verticesBefore += optimizer.countVertices(geometry);

            ObjectNode converted = buildFeature(
                    feature.get("properties"),
                    geometry,
                    optimizer,
                    propertyPreserver
            );
            verticesAfter += optimizer.countVertices(converted.get("geometry"));
            convertedFeatures.add(converted);
        }

        ObjectNode output = buildFeatureCollection(convertedFeatures);
        writeOutput(target, output);

        return new ConvertResult.FileStats(
                name,
                toProjectRelative(target),
                Files.size(source),
                Files.size(target),
                convertedFeatures.size(),
                verticesBefore,
                verticesAfter
        );
    }

    private ObjectNode buildFeature(
            JsonNode properties,
            JsonNode geometry,
            GeometryOptimizer optimizer,
            java.util.function.Function<JsonNode, ObjectNode> propertyPreserver
    ) {
        ObjectNode feature = JsonSanitizer.objectNode();
        feature.put("type", "Feature");
        feature.set("properties", propertyPreserver.apply(properties));
        feature.set("geometry", optimizer.optimizeGeometry(geometry));
        return feature;
    }

    private ObjectNode buildFeatureCollection(ArrayNode features) {
        ObjectNode root = JsonSanitizer.objectNode();
        root.put("type", "FeatureCollection");
        root.set("features", features);
        return root;
    }

    private GeometryOptimizer createOptimizer() {
        return new GeometryOptimizer(
                properties.getSimplifyTolerance(),
                properties.getCoordinatePrecision()
        );
    }

    private void writeOutput(Path target, ObjectNode content) throws IOException {
        backupIfNeeded(target);
        JsonSanitizer.writeCompact(target, content);
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

    private String provinceCode(JsonNode properties) {
        String ma = properties.path("parent_ma").asText("").trim();
        if (!ma.isEmpty()) {
            return sanitizeFileToken(ma);
        }
        String parentTen = properties.path("parent_ten").asText("unknown");
        return sanitizeFileToken(parentTen);
    }

    private String sanitizeFileToken(String raw) {
        String normalized = raw.trim().toLowerCase()
                .replaceAll("[^a-z0-9]+", "_")
                .replaceAll("^_+|_+$", "");
        if (normalized.isEmpty()) {
            return "unknown";
        }
        return normalized;
    }

    private String toProjectRelative(Path absolutePath) {
        return projectPaths.projectRoot().relativize(absolutePath.toAbsolutePath().normalize())
                .toString()
                .replace('\\', '/');
    }
}
