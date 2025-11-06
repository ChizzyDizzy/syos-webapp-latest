package com.syos.web.utils;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Utility class for building HTTP responses
 * Provides standardized JSON response format for all API endpoints
 */
public class ResponseBuilder {
    private static final Logger logger = LoggerFactory.getLogger(ResponseBuilder.class);
    private static final Gson gson = new Gson();
    private static final String CONTENT_TYPE_JSON = "application/json";
    private static final String CHARSET_UTF8 = "UTF-8";

    // Private constructor to prevent instantiation
    private ResponseBuilder() {
    }

    /**
     * Send a success response with data
     */
    public static void success(HttpServletResponse response, String message, Object data) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", data);
        sendJsonResponse(response, HttpServletResponse.SC_OK, responseMap);
    }

    /**
     * Send error response
     */
    public static void error(HttpServletResponse response, String message) throws IOException {
        sendError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, message);
    }

    /**
     * Send error response with custom status code and details
     */
    public static String error(String title, String message, int statusCode) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", false);
        responseMap.put("error", title);
        responseMap.put("message", message);
        responseMap.put("statusCode", statusCode);
        return gson.toJson(responseMap);
    }

    /**
     * Send validation error response
     */
    public static String validationError(Map<String, String> errors) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", false);
        responseMap.put("message", "Validation failed");
        responseMap.put("errors", errors);
        return gson.toJson(responseMap);
    }

    /**
     * Send success response (string return for compatibility)
     */
    public static String success(String message, Object data) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", data);
        return gson.toJson(responseMap);
    }

    /**
     * Send success response with message only
     */
    public static String success(String message) {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        return gson.toJson(responseMap);
    }

    /**
     * Send unauthorized response (401)
     */
    public static void unauthorized(HttpServletResponse response, String message) throws IOException {
        sendError(response, HttpServletResponse.SC_UNAUTHORIZED, message);
    }

    /**
     * Send forbidden response (403)
     */
    public static void forbidden(HttpServletResponse response, String message) throws IOException {
        sendError(response, HttpServletResponse.SC_FORBIDDEN, message);
    }

    /**
     * Send not found response (404)
     */
    public static void notFound(HttpServletResponse response, String message) throws IOException {
        sendError(response, HttpServletResponse.SC_NOT_FOUND, message);
    }

    /**
     * Send bad request response (400)
     */
    public static void badRequest(HttpServletResponse response, String message) throws IOException {
        sendError(response, HttpServletResponse.SC_BAD_REQUEST, message);
    }

    /**
     * Send generic error response with custom status code
     */
    public static void sendError(HttpServletResponse response, int statusCode, String message) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", false);
        responseMap.put("message", message);
        responseMap.put("error", message);
        sendJsonResponse(response, statusCode, responseMap);
    }

    /**
     * Send success response with data and message
     * Overloaded version for JsonObject
     */
    public static void sendSuccess(HttpServletResponse response, JsonObject data, String message) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", gson.fromJson(data, Map.class));
        sendJsonResponse(response, HttpServletResponse.SC_OK, responseMap);
    }

    /**
     * Send success response with list data and message
     * Overloaded version for List<JsonObject>
     */
    public static void sendSuccess(HttpServletResponse response, List<JsonObject> data, String message) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", data);
        sendJsonResponse(response, HttpServletResponse.SC_OK, responseMap);
    }

    /**
     * Send success response with Map data and message
     */
    public static void sendSuccess(HttpServletResponse response, Map<String, Object> data, String message) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", data);
        sendJsonResponse(response, HttpServletResponse.SC_OK, responseMap);
    }

    /**
     * Send JSON response with custom status code
     */
    private static void sendJsonResponse(HttpServletResponse response, int statusCode, Object data) throws IOException {
        response.setStatus(statusCode);
        response.setContentType(CONTENT_TYPE_JSON);
        response.setCharacterEncoding(CHARSET_UTF8);

        try (PrintWriter writer = response.getWriter()) {
            String json = gson.toJson(data);
            writer.write(json);
            writer.flush();
        } catch (IOException e) {
            logger.error("Error writing JSON response: {}", e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Send created response (201) for resource creation
     */
    public static void created(HttpServletResponse response, String message, Object data) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        responseMap.put("data", data);
        sendJsonResponse(response, HttpServletResponse.SC_CREATED, responseMap);
    }

    /**
     * Send no content response (204)
     */
    public static void noContent(HttpServletResponse response) throws IOException {
        response.setStatus(HttpServletResponse.SC_NO_CONTENT);
    }

    /**
     * Send accepted response (202) for async operations
     */
    public static void accepted(HttpServletResponse response, String message) throws IOException {
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("success", true);
        responseMap.put("message", message);
        sendJsonResponse(response, HttpServletResponse.SC_ACCEPTED, responseMap);
    }
}