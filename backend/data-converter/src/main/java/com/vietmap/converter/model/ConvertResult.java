package com.vietmap.converter.model;

import java.util.ArrayList;
import java.util.List;

public class ConvertResult {

    private final List<FileStats> files = new ArrayList<>();
    private long durationMs;

    public List<FileStats> getFiles() {
        return files;
    }

    public long getDurationMs() {
        return durationMs;
    }

    public void setDurationMs(long durationMs) {
        this.durationMs = durationMs;
    }

    public void add(FileStats stats) {
        files.add(stats);
    }

    public record FileStats(
            String name,
            String outputPath,
            long sourceBytes,
            long outputBytes,
            int featureCount,
            long vertexCountBefore,
            long vertexCountAfter
    ) {
    }
}
