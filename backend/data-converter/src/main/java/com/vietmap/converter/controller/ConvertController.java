package com.vietmap.converter.controller;

import com.vietmap.converter.model.ConvertResult;
import com.vietmap.converter.service.DataConvertOrchestrator;
import com.vietmap.converter.service.GeoJsonConvertService;
import com.vietmap.converter.util.ProjectPaths;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/convert")
public class ConvertController {

    private final DataConvertOrchestrator orchestrator;
    private final GeoJsonConvertService geoJsonConvertService;
    private final ProjectPaths projectPaths;

    public ConvertController(
            DataConvertOrchestrator orchestrator,
            GeoJsonConvertService geoJsonConvertService,
            ProjectPaths projectPaths
    ) {
        this.orchestrator = orchestrator;
        this.geoJsonConvertService = geoJsonConvertService;
        this.projectPaths = projectPaths;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "ok");
        body.put("projectRoot", projectPaths.projectRoot().toString());
        return body;
    }

    @PostMapping("/all")
    public ResponseEntity<ConvertResult> convertAll() throws Exception {
        return ResponseEntity.ok(orchestrator.convertAll());
    }

    @PostMapping("/vietnam-complete")
    public ResponseEntity<ConvertResult.FileStats> convertVietnamComplete() throws Exception {
        return ResponseEntity.ok(geoJsonConvertService.convertVietnamComplete());
    }

    @PostMapping("/communes")
    public ResponseEntity<ConvertResult.FileStats> convertCommunes() throws Exception {
        return ResponseEntity.ok(geoJsonConvertService.convertCommunesWithSplit());
    }
}
