package com.syos.web.servlets;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.syos.application.services.ReportService;
import com.syos.domain.entities.User;
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
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.stream.Collectors;

/**
 * Reports Servlet - Handles all report generation REST API endpoints
 *
 * Endpoints:
 * - GET /api/reports/daily-sales      : Generate daily sales report
 * - GET /api/reports/stock            : Generate current stock report
 * - GET /api/reports/reorder          : Generate reorder report (low stock items)
 * - GET /api/reports/reshelve         : Generate reshelve report (expiring items)
 */
@WebServlet(name = "ReportsServlet", urlPatterns = {"/api/reports/*"})
public class ReportsServlet extends HttpServlet {

    private ReportService reportService;
    private Gson gson;
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Override
    public void init() throws ServletException {
        super.init();
        ServiceFactory serviceFactory = ServiceFactory.getInstance();
        this.reportService = serviceFactory.getReportService();
        this.gson = new Gson();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        // Check user authorization - Reports require at least MANAGER role
        HttpSession session = request.getSession(false);
        User currentUser = (User) session.getAttribute("user");

        if (currentUser == null) {
            ResponseBuilder.sendError(response, 401, "Unauthorized. Please login.");
            return;
        }

        if (currentUser.getRole() == UserRole.CASHIER) {
            ResponseBuilder.sendError(response, 403, "Access denied. Manager or Admin role required for reports.");
            return;
        }

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                // List available reports
                handleListReports(request, response);
            } else if (pathInfo.equals("/daily-sales")) {
                // GET /api/reports/daily-sales
                handleDailySalesReport(request, response);
            } else if (pathInfo.equals("/stock")) {
                // GET /api/reports/stock
                handleStockReport(request, response);
            } else if (pathInfo.equals("/reorder")) {
                // GET /api/reports/reorder
                handleReorderReport(request, response);
            } else if (pathInfo.equals("/reshelve")) {
                // GET /api/reports/reshelve
                handleReshelveReport(request, response);
            } else {
                ResponseBuilder.sendError(response, 404, "Report type not found");
            }
        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Internal server error: " + e.getMessage());
        }
    }

    /**
     * GET /api/reports/
     * List all available report types
     */
    private void handleListReports(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        JsonObject reportsInfo = new JsonObject();
        reportsInfo.addProperty("dailySales", "Daily sales report - Query param: date (yyyy-MM-dd, optional)");
        reportsInfo.addProperty("stock", "Current stock report");
        reportsInfo.addProperty("reorder", "Reorder report (low stock items)");
        reportsInfo.addProperty("reshelve", "Reshelve report (expiring items)");

        ResponseBuilder.sendSuccess(response, reportsInfo, "Available report types");
    }

    /**
     * GET /api/reports/daily-sales
     * Generate daily sales report
     *
     * Query parameters:
     * - date: Date for the report (format: yyyy-MM-dd). Defaults to today if not provided.
     * - format: Output format - 'json' or 'text' (default: 'json')
     */
    private void handleDailySalesReport(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Get date parameter (default to today)
            LocalDate date = LocalDate.now();
            String dateParam = request.getParameter("date");

            if (dateParam != null && !dateParam.trim().isEmpty()) {
                try {
                    date = LocalDate.parse(dateParam, DATE_FORMATTER);
                } catch (DateTimeParseException e) {
                    ResponseBuilder.sendError(response, 400, "Invalid date format. Use yyyy-MM-dd");
                    return;
                }
            }

            // Get format parameter (default to json)
            String format = request.getParameter("format");
            if (format == null || format.trim().isEmpty()) {
                format = "json";
            }

            // Generate report
            String reportText = reportService.generateDailySalesReport(date);

            if ("text".equalsIgnoreCase(format)) {
                // Return as plain text
                response.setContentType("text/plain");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write(reportText);
            } else {
                // Return as JSON
                JsonObject reportJson = new JsonObject();
                reportJson.addProperty("reportType", "Daily Sales Report");
                reportJson.addProperty("date", date.toString());
                reportJson.addProperty("generatedAt", LocalDate.now().toString());
                reportJson.addProperty("content", reportText);

                ResponseBuilder.sendSuccess(response, reportJson, "Daily sales report generated successfully");
            }

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to generate daily sales report: " + e.getMessage());
        }
    }

    /**
     * GET /api/reports/stock
     * Generate current stock report
     *
     * Query parameters:
     * - format: Output format - 'json' or 'text' (default: 'json')
     */
    private void handleStockReport(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Get format parameter
            String format = request.getParameter("format");
            if (format == null || format.trim().isEmpty()) {
                format = "json";
            }

            // Generate report
            String reportText = reportService.generateStockReport();

            if ("text".equalsIgnoreCase(format)) {
                // Return as plain text
                response.setContentType("text/plain");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write(reportText);
            } else {
                // Return as JSON
                JsonObject reportJson = new JsonObject();
                reportJson.addProperty("reportType", "Stock Report");
                reportJson.addProperty("generatedAt", LocalDate.now().toString());
                reportJson.addProperty("content", reportText);

                ResponseBuilder.sendSuccess(response, reportJson, "Stock report generated successfully");
            }

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to generate stock report: " + e.getMessage());
        }
    }

    /**
     * GET /api/reports/reorder
     * Generate reorder report (items below reorder threshold)
     *
     * Query parameters:
     * - format: Output format - 'json' or 'text' (default: 'json')
     */
    private void handleReorderReport(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Get format parameter
            String format = request.getParameter("format");
            if (format == null || format.trim().isEmpty()) {
                format = "json";
            }

            // Generate report
            String reportText = reportService.generateReorderReport();

            if ("text".equalsIgnoreCase(format)) {
                // Return as plain text
                response.setContentType("text/plain");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write(reportText);
            } else {
                // Return as JSON
                JsonObject reportJson = new JsonObject();
                reportJson.addProperty("reportType", "Reorder Report");
                reportJson.addProperty("generatedAt", LocalDate.now().toString());
                reportJson.addProperty("content", reportText);

                ResponseBuilder.sendSuccess(response, reportJson, "Reorder report generated successfully");
            }

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to generate reorder report: " + e.getMessage());
        }
    }

    /**
     * GET /api/reports/reshelve
     * Generate reshelve report (items expiring soon)
     *
     * Query parameters:
     * - format: Output format - 'json' or 'text' (default: 'json')
     */
    private void handleReshelveReport(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Get format parameter
            String format = request.getParameter("format");
            if (format == null || format.trim().isEmpty()) {
                format = "json";
            }

            // Generate report
            String reportText = reportService.generateReshelveReport();

            if ("text".equalsIgnoreCase(format)) {
                // Return as plain text
                response.setContentType("text/plain");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write(reportText);
            } else {
                // Return as JSON
                JsonObject reportJson = new JsonObject();
                reportJson.addProperty("reportType", "Reshelve Report");
                reportJson.addProperty("generatedAt", LocalDate.now().toString());
                reportJson.addProperty("content", reportText);

                ResponseBuilder.sendSuccess(response, reportJson, "Reshelve report generated successfully");
            }

        } catch (Exception e) {
            ResponseBuilder.sendError(response, 500, "Failed to generate reshelve report: " + e.getMessage());
        }
    }
}