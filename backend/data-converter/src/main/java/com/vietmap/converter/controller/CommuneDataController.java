package com.vietmap.converter.controller;

import com.vietmap.converter.config.ConverterProperties;
import com.vietmap.converter.util.ProjectPaths;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Files;
import java.nio.file.Path;

/**
 * API phục vụ file commune đã split theo mã tỉnh (dùng sau này, không bắt buộc cho FE hiện tại).
 */
@RestController
@RequestMapping("/api/data")
public class CommuneDataController {

    private final ConverterProperties properties;
    private final ProjectPaths projectPaths;

    public CommuneDataController(ConverterProperties properties, ProjectPaths projectPaths) {
        this.properties = properties;
        this.projectPaths = projectPaths;
    }

    @GetMapping(value = "/communes/{provinceMa}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Resource> getCommunesByProvince(@PathVariable String provinceMa) throws Exception {
        Path splitDir = projectPaths.resolve(properties.getOutputs().getSplitCommunesDir());
        Path file = splitDir.resolve(provinceMa + ".geojson");
        if (!Files.exists(file)) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(new FileSystemResource(file));
    }

    @GetMapping(value = "/communes/manifest", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Resource> getCommuneManifest() {
        Path manifest = projectPaths.resolve(properties.getOutputs().getSplitManifest());
        if (!Files.exists(manifest)) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(new FileSystemResource(manifest));
    }
}
