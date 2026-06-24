package com.vietmap.converter.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "vietmap.converter")
public class ConverterProperties {

    private String projectRoot = "../..";
    private boolean backupBeforeWrite = true;
    private double simplifyTolerance = 0.00008d;
    private int coordinatePrecision = 6;
    private Sources sources = new Sources();
    private Outputs outputs = new Outputs();

    public String getProjectRoot() {
        return projectRoot;
    }

    public void setProjectRoot(String projectRoot) {
        this.projectRoot = projectRoot;
    }

    public boolean isBackupBeforeWrite() {
        return backupBeforeWrite;
    }

    public void setBackupBeforeWrite(boolean backupBeforeWrite) {
        this.backupBeforeWrite = backupBeforeWrite;
    }

    public double getSimplifyTolerance() {
        return simplifyTolerance;
    }

    public void setSimplifyTolerance(double simplifyTolerance) {
        this.simplifyTolerance = simplifyTolerance;
    }

    public int getCoordinatePrecision() {
        return coordinatePrecision;
    }

    public void setCoordinatePrecision(int coordinatePrecision) {
        this.coordinatePrecision = coordinatePrecision;
    }

    public Sources getSources() {
        return sources;
    }

    public void setSources(Sources sources) {
        this.sources = sources;
    }

    public Outputs getOutputs() {
        return outputs;
    }

    public void setOutputs(Outputs outputs) {
        this.outputs = outputs;
    }

    public static class Sources {
        private String communes = "assets/geo/communes.geojson";
        private String vietnamComplete = "assets/geo/vietnam_complete.geojson";
        private String tourism = "assets/data/tourism_destinations.json";

        public String getCommunes() {
            return communes;
        }

        public void setCommunes(String communes) {
            this.communes = communes;
        }

        public String getVietnamComplete() {
            return vietnamComplete;
        }

        public void setVietnamComplete(String vietnamComplete) {
            this.vietnamComplete = vietnamComplete;
        }

        public String getTourism() {
            return tourism;
        }

        public void setTourism(String tourism) {
            this.tourism = tourism;
        }
    }

    public static class Outputs {
        private String communesMerged = "assets/geo/communes.geojson";
        private String vietnamComplete = "assets/geo/vietnam_complete.geojson";
        private String tourism = "assets/data/tourism_destinations.json";
        private String splitCommunesDir = "assets/geo/communes_by_province";
        private String splitManifest = "assets/geo/communes_by_province/manifest.json";

        public String getCommunesMerged() {
            return communesMerged;
        }

        public void setCommunesMerged(String communesMerged) {
            this.communesMerged = communesMerged;
        }

        public String getVietnamComplete() {
            return vietnamComplete;
        }

        public void setVietnamComplete(String vietnamComplete) {
            this.vietnamComplete = vietnamComplete;
        }

        public String getTourism() {
            return tourism;
        }

        public void setTourism(String tourism) {
            this.tourism = tourism;
        }

        public String getSplitCommunesDir() {
            return splitCommunesDir;
        }

        public void setSplitCommunesDir(String splitCommunesDir) {
            this.splitCommunesDir = splitCommunesDir;
        }

        public String getSplitManifest() {
            return splitManifest;
        }

        public void setSplitManifest(String splitManifest) {
            this.splitManifest = splitManifest;
        }
    }
}
