package com.syos.web.servlets;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.syos.application.services.SalesService;
import com.syos.domain.entities.Bill;
import com.syos.domain.entities.Item;
import com.syos.domain.entities.User;
import com.syos.domain.exceptions.*;
import com.syos.infrastructure.factories.ServiceFactory;
import com.syos.web.session.SessionManager;
import com.syos.web.utils.JsonConverter;
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
 * Sales Servlet - Handles all sales-related REST API endpoints
 *
 * Endpoints:
 * - GET  /api/sales/available-items  : Get all items available for sale
 * - POST /api/sales/create           : Create a new sale
 * - GET  /api/sales/bills            : Get all bills (with optional date filter)
 * - GET  /api/sales/bills/{billNumber}: Get specific bill by number
 * - GET  /api/sales/today            : Get today's bills
 */
@WebServlet(name = "SalesServlet", urlPatterns = {"/api/sales/*"})
public class SalesServlet extends HttpServlet {

    private SalesService salesService;
    private Gson gson;
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Override
    public void init() throws ServletException {
        super.init();
        ServiceFactory serviceFactory = ServiceFactory.getInstance();
        this.salesService = serviceFactory.getSalesService();
        this.gson = new Gson();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                // GET /api/sales/ - List all bills
                handleGetAllBills(request, response);
            } else if (pathInfo.equals("/available-items")) {
                // GET /api/sales/available-items
                handleGetAvailableItems(request, response);
            } else if (pathInfo.equals("/today")) {
                // GET /api/sales/today
                handleGetTodaysBills(request, response);
            } else if (pathInfo.matches("/\\d+")) {
                // GET /api/sales/{billNumber}
                handleGetBillByNumber(request, response, pathInfo);
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
            if (pathInfo != null && pathInfo.equals("/create")) {
                // POST /api/sales/create
                handleCreateSale(request, response);
            } else {
                ResponseBuilder.sendError(response, 404, "Endpoint not found");
            }
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    /**
     * GET /api/sales/available-items
     * Returns all items that are available for sale (on shelf with quantity > 0)
     */
    private void handleGetAvailableItems(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Item> availableItems = salesService.getAvailableItems();

            // Convert to JSON-friendly format
            List<JsonObject> itemsJson = availableItems.stream()
                    .map(this::itemToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, itemsJson, "Available items retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve available items: " + e.getMessage());
        }
    }

    /**
     * POST /api/sales/create
     * Creates a new sale transaction
     *
     * Request body format:
     * {
     *   "items": [
     *     {"itemCode": "MILK001", "quantity": 2},
     *     {"itemCode": "BREAD001", "quantity": 1}
     *   ],
     *   "cashTendered": 50.00,
     *   "discount": 0.00,
     *   "transactionType": "IN_STORE" // or "ONLINE"
     * }
     */
    private void handleCreateSale(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Parse request body
            String requestBody = request.getReader().lines().collect(Collectors.joining());
            JsonObject saleRequest = gson.fromJson(requestBody, JsonObject.class);

            // Get user from session
            HttpSession session = request.getSession(false);
            User currentUser = (User) session.getAttribute("user");

            // Validate request
            if (!saleRequest.has("items") || !saleRequest.has("cashTendered")) {
                ResponseBuilder.sendError(response, 400, "Missing required fields: items and cashTendered");
                return;
            }

            // Start building the sale
            SalesService.SaleBuilder saleBuilder = salesService.startNewSale();

            // Add items to sale
            var itemsArray = saleRequest.getAsJsonArray("items");
            for (int i = 0; i < itemsArray.size(); i++) {
                JsonObject itemObj = itemsArray.get(i).getAsJsonObject();
                String itemCode = itemObj.get("itemCode").getAsString();
                int quantity = itemObj.get("quantity").getAsInt();

                try {
                    saleBuilder.addItem(itemCode, quantity);
                } catch (ItemNotFoundException e) {
                    ResponseBuilder.sendError(response, 404, "Item not found: " + itemCode);
                    return;
                } catch (InsufficientStockException e) {
                    ResponseBuilder.sendError(response, 400, "Insufficient stock for item: " + itemCode);
                    return;
                } catch (IllegalStateException e) {
                    ResponseBuilder.sendError(response, 400, e.getMessage());
                    return;
                }
            }

            // Apply discount if provided
            if (saleRequest.has("discount")) {
                BigDecimal discount = saleRequest.get("discount").getAsBigDecimal();
                if (discount.compareTo(BigDecimal.ZERO) > 0) {
                    saleBuilder.applyDiscount(discount);
                }
            }

            // Set transaction type if provided
            String transactionType = saleRequest.has("transactionType")
                    ? saleRequest.get("transactionType").getAsString()
                    : "IN_STORE";

            // Complete the sale
            BigDecimal cashTendered = saleRequest.get("cashTendered").getAsBigDecimal();
            Bill bill;

            try {
                if ("ONLINE".equalsIgnoreCase(transactionType)) {
                    bill = saleBuilder.completeOnlineSale(cashTendered);
                } else {
                    bill = saleBuilder.completeSale(cashTendered);
                }
            } catch (EmptySaleException e) {
                ResponseBuilder.sendError(response, 400, "Cannot create sale with no items");
                return;
            } catch (InsufficientPaymentException e) {
                ResponseBuilder.sendError(response, 400, "Insufficient payment: " + e.getMessage());
                return;
            }

            // Save the bill
            salesService.saveBill(bill);

            // Convert bill to JSON response
            JsonObject billJson = billToJson(bill);

            ResponseBuilder.sendSuccess(response, billJson, "Sale created successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to create sale: " + e.getMessage());
        }
    }

    /**
     * GET /api/sales/
     * Get all bills, with optional date filter
     * Query parameters:
     * - date: Filter bills by date (format: yyyy-MM-dd)
     */
    private void handleGetAllBills(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            String dateParam = request.getParameter("date");
            List<Bill> bills;

            if (dateParam != null && !dateParam.trim().isEmpty()) {
                // Filter by date
                try {
                    LocalDate date = LocalDate.parse(dateParam, DATE_FORMATTER);
                    bills = salesService.getBillsByDate(date);
                } catch (DateTimeParseException e) {
                    ResponseBuilder.sendError(response, 400, "Invalid date format. Use yyyy-MM-dd");
                    return;
                }
            } else {
                // Get all bills
                bills = salesService.getAllBills();
            }

            // Convert to JSON
            List<JsonObject> billsJson = bills.stream()
                    .map(this::billToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, billsJson,
                    dateParam != null ? "Bills retrieved for date: " + dateParam : "All bills retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve bills: " + e.getMessage());
        }
    }

    /**
     * GET /api/sales/today
     * Get all bills for today
     */
    private void handleGetTodaysBills(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            List<Bill> bills = salesService.getBillsForToday();

            // Convert to JSON
            List<JsonObject> billsJson = bills.stream()
                    .map(this::billToJson)
                    .collect(Collectors.toList());

            ResponseBuilder.sendSuccess(response, billsJson, "Today's bills retrieved successfully");

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve today's bills: " + e.getMessage());
        }
    }

    /**
     * GET /api/sales/{billNumber}
     * Get a specific bill by its number
     */
    private void handleGetBillByNumber(HttpServletRequest request, HttpServletResponse response, String pathInfo)
            throws IOException {

        try {
            // Extract bill number from path
            String billNumberStr = pathInfo.substring(1); // Remove leading "/"
            int billNumber = Integer.parseInt(billNumberStr);

            Bill bill = salesService.getBillByNumber(billNumber);

            if (bill == null) {
                ResponseBuilder.sendError(response, 404, "Bill not found: " + billNumber);
                return;
            }

            // Convert to JSON
            JsonObject billJson = billToJson(bill);

            ResponseBuilder.sendSuccess(response, billJson, "Bill retrieved successfully");

        } catch (NumberFormatException e) {
            ResponseBuilder.sendError(response, 400, "Invalid bill number format");
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to retrieve bill: " + e.getMessage());
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
        if (item.getExpiryDate() != null) {
            json.addProperty("expiryDate", item.getExpiryDate().toString());
            json.addProperty("daysUntilExpiry", item.daysUntilExpiry());
        }
        return json;
    }

    /**
     * Convert Bill entity to JSON object
     */
    private JsonObject billToJson(Bill bill) {
        JsonObject json = new JsonObject();
        json.addProperty("billNumber", bill.getBillNumber().getValue());
        json.addProperty("billDate", bill.getBillDate().toString());
        json.addProperty("totalAmount", bill.getTotalAmount().getValue());
        json.addProperty("discount", bill.getDiscount().getValue());
        json.addProperty("cashTendered", bill.getCashTendered().getValue());
        json.addProperty("change", bill.getChange().getValue());
        json.addProperty("transactionType", bill.getTransactionType().name());

        // Add items
        var itemsArray = new com.google.gson.JsonArray();
        for (var billItem : bill.getItems()) {
            JsonObject itemJson = new JsonObject();
            itemJson.addProperty("itemCode", billItem.getItem().getCode().getValue());
            itemJson.addProperty("itemName", billItem.getItem().getName());
            itemJson.addProperty("quantity", billItem.getQuantity().getValue());

            // FIXED: Changed from getUnitPrice() and getSubtotal() to:
            itemJson.addProperty("unitPrice", billItem.getItem().getPrice().getValue());
            itemJson.addProperty("subtotal", billItem.getTotalPrice().getValue());

            itemsArray.add(itemJson);
        }
        json.add("items", itemsArray);

        return json;
    }
}