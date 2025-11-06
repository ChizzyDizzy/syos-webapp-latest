package com.syos.web.servlets;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.syos.application.services.InventoryService;
import com.syos.domain.entities.Item;
import com.syos.domain.entities.User;
import com.syos.domain.exceptions.*;
import com.syos.domain.valueobjects.UserRole;
import com.syos.infrastructure.factories.ServiceFactory;
import com.syos.web.utils.ResponseBuilder;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Inventory Servlet - Handles all inventory-related REST API endpoints
 *
 * Endpoints:
 * - GET  /api/inventory/items           : Get all items
 * - GET  /api/inventory/items/{code}    : Get item by code
 * - POST /api/inventory/add-stock       : Add new stock (requires MANAGER/ADMIN role)
 * - POST /api/inventory/move-to-shelf   : Move items to shelf (requires MANAGER/ADMIN role)
 * - GET  /api/inventory/in-store        : Get items in store
 * - GET  /api/inventory/on-shelf        : Get items on shelf
 * - GET  /api/inventory/low-stock       : Get low stock items
 * - GET  /api/inventory/expiring        : Get items expiring soon
 * - GET  /api/inventory/statistics      : Get inventory statistics
 * - PUT  /api/inventory/update-price    : Update item price (requires ADMIN role)
 */
@WebServlet(name = "InventoryServlet", urlPatterns = {"/api/inventory/*"})
public class InventoryServlet extends HttpServlet {

    private InventoryService inventoryService;
    private Gson gson;
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Override
    public void init() throws ServletException {
        super.init();
        ServiceFactory serviceFactory = ServiceFactory.getInstance();
        this.inventoryService = serviceFactory.getInventoryService();
        this.gson = new Gson();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/items")) {
                // GET /api/inventory/items - Get all items
                handleGetAllItems(request, response);
            } else if (pathInfo.startsWith("/items/")) {
                // GET /api/inventory/items/{code}
                handleGetItemByCode(request, response, pathInfo);
            } else if (pathInfo.equals("/in-store")) {
                // GET /api/inventory/in-store
                handleGetItemsInStore(request, response);
            } else if (pathInfo.equals("/on-shelf")) {
                // GET /api/inventory/on-shelf
                handleGetItemsOnShelf(request, response);
            } else if (pathInfo.equals("/low-stock")) {
                // GET /api/inventory/low-stock
                handleGetLowStockItems(request, response);
            } else if (pathInfo.equals("/expiring")) {
                // GET /api/inventory/expiring
                handleGetExpiringItems(request, response);
            } else if (pathInfo.equals("/statistics")) {
                // GET /api/inventory/statistics
                handleGetStatistics(request, response);
            } else {
                ResponseBuilder.sendError(response, 404, "Endpoint not found");
            }
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo != null && pathInfo.equals("/add-stock")) {
                // POST /api/inventory/add-stock
                handleAddStock(request, response);
            } else if (pathInfo != null && pathInfo.equals("/move-to-shelf")) {
                // POST /api/inventory/move-to-shelf
                handleMoveToShelf(request, response);
            } else {
                ResponseBuilder.sendError(response, 404, "Endpoint not found");
            }
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo != null && pathInfo.equals("/update-price")) {
                // PUT /api/inventory/update-price
                handleUpdatePrice(request, response);
            } else {
                ResponseBuilder.sendError(response, 404, "Endpoint not found");
            }
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/items
     * Get all inventory items
     */
    private void handleGetAllItems(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Item> items = inventoryService.getAllItems();

            // Convert to JSON
            List<JsonObject> itemsJson = items.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson, "Items retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve items: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/items/{code}
     * Get a specific item by its code
     */
    private void handleGetItemByCode(HttpServletRequest request, HttpServletResponse response, String pathInfo)
            throws IOException {

        try {
            // Extract item code from path
            String itemCode = pathInfo.substring("/items/".length()).toUpperCase();

            Item item = inventoryService.getItemByCode(itemCode);

            if (item == null) {
                ResponseBuilder.sendError(response, 404, "Item not found: " + itemCode);
                return;
            }

            // Convert to JSON
            JsonObject itemJson = itemToJson(item);

            ResponseBuilder.sendSuccess(response, itemJson, "Item retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve item: " + e.getMessage());
        }
    }

    /**
     * POST /api/inventory/add-stock
     * Add new stock to inventory (requires MANAGER or ADMIN role)
     *
     * Request body:
     * {
     *   "code": "MILK001",
     *   "name": "Full Cream Milk 1L",
     *   "price": 2.50,
     *   "quantity": 100,
     *   "expiryDate": "2025-12-31"
     * }
     */
    private void handleAddStock(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        // Check user authorization
        HttpSession session = request.getSession(false);
        User currentUser = (User) session.getAttribute("user");

        if (!currentUser.hasRole(UserRole.MANAGER) && !currentUser.hasRole(UserRole.ADMIN)) {
            ResponseBuilder.sendError(response, 403, "Access denied. Manager or Admin role required.");
            return;
        }

        try {
            // Parse request body
            String requestBody = request.getReader().lines().collect(Collectors.joining());
            JsonObject stockRequest = gson.fromJson(requestBody, JsonObject.class);

            // Validate required fields
            if (!stockRequest.has("code") || !stockRequest.has("name") ||
                    !stockRequest.has("price") || !stockRequest.has("quantity")) {
                ResponseBuilder.sendError(response, 400, "Missing required fields");
                return;
            }

            // Extract fields
            String code = stockRequest.get("code").getAsString().toUpperCase();
            String name = stockRequest.get("name").getAsString();
            BigDecimal price = stockRequest.get("price").getAsBigDecimal();
            int quantity = stockRequest.get("quantity").getAsInt();

            // Parse expiry date if provided
            LocalDate expiryDate = null;
            if (stockRequest.has("expiryDate")) {
                try {
                    expiryDate = LocalDate.parse(
                            stockRequest.get("expiryDate").getAsString(),
                            DATE_FORMATTER
                    );
                } catch (DateTimeParseException e) {
                    ResponseBuilder.sendError(response, 400, "Invalid expiry date format. Use yyyy-MM-dd");
                    return;
                }
            }

            // Validate inputs
            if (quantity <= 0) {
                ResponseBuilder.sendError(response, 400, "Quantity must be greater than zero");
                return;
            }

            if (price.compareTo(BigDecimal.ZERO) <= 0) {
                ResponseBuilder.sendError(response, 400, "Price must be greater than zero");
                return;
            }

            // Add stock
            inventoryService.addStock(code, name, price, quantity, expiryDate);

            // Get the updated/new item
            Item item = inventoryService.getItemByCode(code);
            JsonObject itemJson = itemToJson(item);

            ResponseBuilder.sendSuccess(response, itemJson, "Stock added successfully");

        } catch (InvalidItemCodeException e) {
            ResponseBuilder.sendError(response, 400, "Invalid item code: " + e.getMessage());
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to add stock: " + e.getMessage());
        }
    }

    /**
     * POST /api/inventory/move-to-shelf
     * Move items from store to shelf (requires MANAGER or ADMIN role)
     *
     * Request body:
     * {
     *   "itemCode": "MILK001",
     *   "quantity": 50
     * }
     */
    private void handleMoveToShelf(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        // Check user authorization
        HttpSession session = request.getSession(false);
        User currentUser = (User) session.getAttribute("user");

        if (!currentUser.hasRole(UserRole.MANAGER) && !currentUser.hasRole(UserRole.ADMIN)) {
            ResponseBuilder.sendError(response, 403, "Access denied. Manager or Admin role required.");
            return;
        }

        try {
            // Parse request body
            String requestBody = request.getReader().lines().collect(Collectors.joining());
            JsonObject moveRequest = gson.fromJson(requestBody, JsonObject.class);

            // Validate required fields
            if (!moveRequest.has("itemCode") || !moveRequest.has("quantity")) {
                ResponseBuilder.sendError(response, 400, "Missing required fields: itemCode and quantity");
                return;
            }

            String itemCode = moveRequest.get("itemCode").getAsString().toUpperCase();
            int quantity = moveRequest.get("quantity").getAsInt();

            // Validate quantity
            if (quantity <= 0) {
                ResponseBuilder.sendError(response, 400, "Quantity must be greater than zero");
                return;
            }

            // Move to shelf
            try {
                inventoryService.moveToShelf(itemCode, quantity);
            } catch (ItemNotFoundException e) {
                ResponseBuilder.sendError(response, 404, "Item not found: " + itemCode);
                return;
            } catch (InvalidStateTransitionException e) {
                ResponseBuilder.sendError(response, 400, "Invalid state transition: " + e.getMessage());
                return;
            } catch (InsufficientStockException e) {
                ResponseBuilder.sendError(response, 400, "Insufficient stock: " + e.getMessage());
                return;
            }

            // Get updated item
            Item item = inventoryService.getItemByCode(itemCode);
            JsonObject itemJson = itemToJson(item);

            ResponseBuilder.sendSuccess(response, itemJson,
                    String.format("Moved %d units to shelf successfully", quantity));

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to move items to shelf: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/in-store
     * Get all items currently in store
     */
    private void handleGetItemsInStore(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Item> items = inventoryService.getItemsInStore();

            List<JsonObject> itemsJson = items.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson, "In-store items retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve in-store items: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/on-shelf
     * Get all items currently on shelf
     */
    private void handleGetItemsOnShelf(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Item> items = inventoryService.getItemsOnShelf();

            List<JsonObject> itemsJson = items.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson, "On-shelf items retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve on-shelf items: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/low-stock
     * Get items with low stock (below reorder threshold)
     */
    private void handleGetLowStockItems(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Item> items = inventoryService.getLowStockItems();

            List<JsonObject> itemsJson = items.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson, "Low stock items retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve low stock items: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/expiring
     * Get items expiring soon
     * Query parameter: days (optional, default: 7)
     */
    private void handleGetExpiringItems(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Get days parameter (default to 7)
            int days = 7;
            String daysParam = request.getParameter("days");
            if (daysParam != null) {
                try {
                    days = Integer.parseInt(daysParam);
                    if (days <= 0) {
                        ResponseBuilder.sendError(response, 400, "Days parameter must be positive");
                        return;
                    }
                } catch (NumberFormatException e) {
                    ResponseBuilder.sendError(response, 400, "Invalid days parameter");
                    return;
                }
            }

            List<Item> items = inventoryService.getExpiringItems(days);

            List<JsonObject> itemsJson = items.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson,
                    String.format("Items expiring within %d days retrieved successfully", days));

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve expiring items: " + e.getMessage());
        }
    }

    /**
     * GET /api/inventory/statistics
     * Get inventory statistics
     */
    private void handleGetStatistics(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            InventoryService.InventoryStatistics stats = inventoryService.getInventoryStatistics();

            JsonObject statsJson = new JsonObject();
            statsJson.addProperty("totalItems", stats.totalItems);
            statsJson.addProperty("totalQuantity", stats.totalQuantity);
            statsJson.addProperty("totalValue", stats.totalValue);
            statsJson.addProperty("inStoreCount", stats.inStoreCount);
            statsJson.addProperty("onShelfCount", stats.onShelfCount);
            statsJson.addProperty("expiredCount", stats.expiredCount);
            statsJson.addProperty("lowStockCount", stats.lowStockCount);
            statsJson.addProperty("expiringCount", stats.expiringCount);

            ResponseBuilder.sendSuccess(response, statsJson, "Statistics retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve statistics: " + e.getMessage());
        }
    }

    /**
     * PUT /api/inventory/update-price
     * Update item price (requires ADMIN role)
     *
     * Request body:
     * {
     *   "itemCode": "MILK001",
     *   "newPrice": 2.75
     * }
     */
    private void handleUpdatePrice(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        // Check user authorization
        HttpSession session = request.getSession(false);
        User currentUser = (User) session.getAttribute("user");

        if (!currentUser.hasRole(UserRole.ADMIN)) {
            ResponseBuilder.sendError(response, 403, "Access denied. Admin role required.");
            return;
        }

        try {
            // Parse request body
            String requestBody = request.getReader().lines().collect(Collectors.joining());
            JsonObject priceRequest = gson.fromJson(requestBody, JsonObject.class);

            // Validate required fields
            if (!priceRequest.has("itemCode") || !priceRequest.has("newPrice")) {
                ResponseBuilder.sendError(response, 400, "Missing required fields: itemCode and newPrice");
                return;
            }

            String itemCode = priceRequest.get("itemCode").getAsString().toUpperCase();
            BigDecimal newPrice = priceRequest.get("newPrice").getAsBigDecimal();

            // Validate price
            if (newPrice.compareTo(BigDecimal.ZERO) <= 0) {
                ResponseBuilder.sendError(response, 400, "Price must be greater than zero");
                return;
            }

            // Update price
            try {
                inventoryService.updateItemPrice(itemCode, newPrice);
            } catch (ItemNotFoundException e) {
                ResponseBuilder.sendError(response, 404, "Item not found: " + itemCode);
                return;
            }

            // Get updated item
            Item item = inventoryService.getItemByCode(itemCode);
            JsonObject itemJson = itemToJson(item);

            ResponseBuilder.sendSuccess(response, itemJson, "Price updated successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to update price: " + e.getMessage());
        }
    }

    /**
     * Convert Item entity to JSON object
     */
    private JsonObject itemToJson(Item item) {
        JsonObject json = new JsonObject();
        json.addProperty("code", item.getCode().getValue());
        json.addProperty("name", item.getName());
        json.addProperty("price", item.getPrice().getValue());
        json.addProperty("quantity", item.getQuantity().getValue());
        json.addProperty("state", item.getState().getStateName());
        json.addProperty("purchaseDate", item.getPurchaseDate().toString());

        if (item.getExpiryDate() != null) {
            json.addProperty("expiryDate", item.getExpiryDate().toString());
            json.addProperty("daysUntilExpiry", item.daysUntilExpiry());
            json.addProperty("isExpired", item.isExpired());
        }

        return json;
    }
}