package com.vietmap.converter.util;

import com.vietmap.converter.config.ConverterProperties;
import org.springframework.stereotype.Component;

import java.nio.file.Path;
import java.nio.file.Paths;

@Component
public class ProjectPaths {

    private final ConverterProperties properties;

    public ProjectPaths(ConverterProperties properties) {
        this.properties = properties;
    }

    public Path projectRoot() {
        Path configured = Paths.get(properties.getProjectRoot());
        if (configured.isAbsolute()) {
            return configured.normalize();
        }
        return Paths.get(System.getProperty("user.dir"))
                .resolve(configured)
                .normalize()
                .toAbsolutePath();
    }

    public Path resolve(String relativePath) {
        return projectRoot().resolve(relativePath).normalize();
    }
}
