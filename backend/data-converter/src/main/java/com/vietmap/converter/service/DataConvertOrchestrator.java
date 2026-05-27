package com.vietmap.converter.service;

import com.vietmap.converter.model.ConvertResult;
import org.springframework.stereotype.Service;

@Service
public class DataConvertOrchestrator {

    private final GeoJsonConvertService geoJsonConvertService;
    private final TourismConvertService tourismConvertService;

    public DataConvertOrchestrator(
            GeoJsonConvertService geoJsonConvertService,
            TourismConvertService tourismConvertService
    ) {
        this.geoJsonConvertService = geoJsonConvertService;
        this.tourismConvertService = tourismConvertService;
    }

    public ConvertResult convertAll() throws Exception {
        long started = System.currentTimeMillis();
        ConvertResult result = new ConvertResult();

        result.add(geoJsonConvertService.convertVietnamComplete());
        result.add(geoJsonConvertService.convertCommunesWithSplit());
        result.add(tourismConvertService.convertTourism());

        result.setDurationMs(System.currentTimeMillis() - started);
        return result;
    }
}
