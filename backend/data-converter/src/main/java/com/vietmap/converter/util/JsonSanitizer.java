package com.vietmap.converter.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public final class JsonSanitizer {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private JsonSanitizer() {
    }

    public static String readAndFixJsonText(Path path) throws IOException {
        String raw = Files.readString(path, StandardCharsets.UTF_8);
        return raw
                .replace(": NaN", ": null")
                .replace(":NaN", ":null")
                .replace("[NaN", "[null")
                .replace(", NaN", ", null")
                .replace(",NaN", ",null");
    }

    public static JsonNode readTree(Path path) throws IOException {
        return MAPPER.readTree(readAndFixJsonText(path));
    }

    public static void writeCompact(Path path, JsonNode node) throws IOException {
        Files.createDirectories(path.getParent());
        byte[] bytes = MAPPER.writer().writeValueAsBytes(node);
        Files.write(path, bytes);
    }

    public static ObjectNode objectNode() {
        return MAPPER.createObjectNode();
    }

    public static ArrayNode arrayNode() {
        return MAPPER.createArrayNode();
    }

    public static ObjectMapper mapper() {
        return MAPPER;
    }
}
