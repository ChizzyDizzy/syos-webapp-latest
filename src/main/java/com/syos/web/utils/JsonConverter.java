package com.syos.web.utils;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;

import javax.servlet.http.HttpServletRequest;
import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Type;

/**
 * Utility class for JSON serialization and deserialization using Gson
 */
public class JsonConverter {
    private static final Gson gson = new GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss")
            .setPrettyPrinting()
            .create();

    /**
     * Convert an object to JSON string
     */
    public static String toJson(Object obj) {
        if (obj == null) {
            return "{}";
        }
        return gson.toJson(obj);
    }

    /**
     * Convert JSON string to an object of specified class
     */
    public static <T> T fromJson(String json, Class<T> classOfT) {
        if (json == null || json.trim().isEmpty()) {
            return null;
        }
        try {
            return gson.fromJson(json, classOfT);
        } catch (JsonSyntaxException e) {
            throw new IllegalArgumentException("Invalid JSON format: " + e.getMessage(), e);
        }
    }

    /**
     * Convert JSON string to an object of specified type (for generics)
     */
    public static <T> T fromJson(String json, Type typeOfT) {
        if (json == null || json.trim().isEmpty()) {
            return null;
        }
        try {
            return gson.fromJson(json, typeOfT);
        } catch (JsonSyntaxException e) {
            throw new IllegalArgumentException("Invalid JSON format: " + e.getMessage(), e);
        }
    }

    /**
     * Read request body from HttpServletRequest and return as String
     */
    public static String readRequestBody(HttpServletRequest request) throws IOException {
        StringBuilder buffer = new StringBuilder();
        String line;

        try (BufferedReader reader = request.getReader()) {
            while ((line = reader.readLine()) != null) {
                buffer.append(line);
            }
        }

        return buffer.toString();
    }

    /**
     * Read request body and convert to object of specified class
     */
    public static <T> T readRequestBody(HttpServletRequest request, Class<T> classOfT) throws IOException {
        String body = readRequestBody(request);
        return fromJson(body, classOfT);
    }

    /**
     * Get the Gson instance for direct use if needed
     */
    public static Gson getGson() {
        return gson;
    }

    /**
     * Pretty print JSON string
     */
    public static String prettify(String json) {
        if (json == null || json.trim().isEmpty()) {
            return "{}";
        }
        Object obj = gson.fromJson(json, Object.class);
        return gson.toJson(obj);
    }

    /**
     * Check if a string is valid JSON
     */
    public static boolean isValidJson(String json) {
        if (json == null || json.trim().isEmpty()) {
            return false;
        }
        try {
            gson.fromJson(json, Object.class);
            return true;
        } catch (JsonSyntaxException e) {
            return false;
        }
    }
}