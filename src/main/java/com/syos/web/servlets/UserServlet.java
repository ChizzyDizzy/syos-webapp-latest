package com.syos.web.servlets;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import com.syos.application.services.UserService;
import com.syos.domain.entities.User;
import com.syos.domain.exceptions.UserAlreadyExistsException;
import com.syos.domain.valueobjects.UserRole;
import com.syos.infrastructure.factories.ServiceFactory;
import com.syos.web.dto.*;
import com.syos.web.session.SessionManager;
import com.syos.web.utils.JsonConverter;
import com.syos.web.utils.ResponseBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * User Servlet
 * Handles all user-related operations: login, register, logout, profile
 *
 * Endpoints:
 * POST /api/user/login - User authentication
 * POST /api/user/register - New user registration (Admin only)
 * POST /api/user/logout - User logout
 * GET /api/user/profile - Get current user profile
 * GET /api/user/session-info - Get session information
 */
@WebServlet(name = "UserServlet", urlPatterns = {"/api/user/*"})
public class UserServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(UserServlet.class);
    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    private UserService userService;

    @Override
    public void init() throws ServletException {
        logger.info("Initializing UserServlet...");
        ServiceFactory serviceFactory = ServiceFactory.getInstance();
        this.userService = serviceFactory.getUserService();
        logger.info("UserServlet initialized successfully");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                sendError(response, "Invalid endpoint", HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            switch (pathInfo) {
                case "/login":
                    handleLogin(request, response);
                    break;
                case "/register":
                    handleRegister(request, response);
                    break;
                case "/logout":
                    handleLogout(request, response);
                    break;
                default:
                    sendError(response, "Endpoint not found: " + pathInfo, HttpServletResponse.SC_NOT_FOUND);
            }

        } catch (Exception e) {
            logger.error("Error in UserServlet POST: ", e);
            sendError(response, "Internal server error: " + e.getMessage(),
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                sendError(response, "Invalid endpoint", HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            switch (pathInfo) {
                case "/profile":
                    handleGetProfile(request, response);
                    break;
                case "/session-info":
                    handleGetSessionInfo(request, response);
                    break;
                default:
                    sendError(response, "Endpoint not found: " + pathInfo, HttpServletResponse.SC_NOT_FOUND);
            }

        } catch (Exception e) {
            logger.error("Error in UserServlet GET: ", e);
            sendError(response, "Internal server error: " + e.getMessage(),
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Handle user login
     * POST /api/user/login
     */
    private void handleLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        try {
            // Parse request body
            String json = JsonConverter.readRequestBody(request);
            LoginRequest loginRequest = gson.fromJson(json, LoginRequest.class);

            // Validate input
            Map<String, String> validationErrors = validateLoginRequest(loginRequest);
            if (!validationErrors.isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write(ResponseBuilder.validationError(validationErrors));
                return;
            }

            // Attempt login
            boolean loginSuccessful = userService.login(
                    loginRequest.getUsername().toLowerCase(),
                    loginRequest.getPassword()
            );

            if (loginSuccessful) {
                User user = userService.getCurrentUser();

                // Create session
                SessionManager.createUserSession(request, user);

                // Build response
                LoginResponse loginResponse = new LoginResponse(
                        user.getId().getValue(),
                        user.getUsername(),
                        user.getEmail(),
                        user.getRole().name(),
                        SessionManager.getLoginTime(request)
                );

                logger.info("User logged in successfully: {} (Role: {})",
                        user.getUsername(), user.getRole());

                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write(
                        ResponseBuilder.success("Login successful", loginResponse)
                );

            } else {
                logger.warn("Failed login attempt for username: {}", loginRequest.getUsername());
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write(
                        ResponseBuilder.error("Authentication Failed",
                                "Invalid username or password",
                                HttpServletResponse.SC_UNAUTHORIZED)
                );
            }

        } catch (JsonSyntaxException e) {
            logger.error("Invalid JSON in login request", e);
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    ResponseBuilder.error("Invalid Request",
                            "Malformed JSON in request body",
                            HttpServletResponse.SC_BAD_REQUEST)
            );
        }
    }

    /**
     * Handle user registration
     * POST /api/user/register
     * Requires Admin role
     */
    private void handleRegister(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        // Check if user has admin role
        if (!SessionManager.hasRole(request, UserRole.ADMIN)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.getWriter().write(
                    ResponseBuilder.error("Forbidden",
                            "Only administrators can register new users",
                            HttpServletResponse.SC_FORBIDDEN)
            );
            return;
        }

        try {
            // Parse request body
            String json = JsonConverter.readRequestBody(request);
            RegisterRequest registerRequest = gson.fromJson(json, RegisterRequest.class);

            // Validate input
            Map<String, String> validationErrors = validateRegisterRequest(registerRequest);
            if (!validationErrors.isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write(ResponseBuilder.validationError(validationErrors));
                return;
            }

            // Register user
            userService.registerUser(
                    registerRequest.getUsername().toLowerCase(),
                    registerRequest.getEmail(),
                    registerRequest.getPassword(),
                    UserRole.valueOf(registerRequest.getRole())
            );

            logger.info("New user registered: {} (Role: {}) by Admin: {}",
                    registerRequest.getUsername(),
                    registerRequest.getRole(),
                    SessionManager.getCurrentUsername(request));

            response.setStatus(HttpServletResponse.SC_CREATED);
            response.getWriter().write(
                    ResponseBuilder.success("User registered successfully")
            );

        } catch (UserAlreadyExistsException e) {
            logger.warn("Registration failed - user already exists: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_CONFLICT);
            response.getWriter().write(
                    ResponseBuilder.error("User Already Exists",
                            e.getMessage(),
                            HttpServletResponse.SC_CONFLICT)
            );
        } catch (JsonSyntaxException e) {
            logger.error("Invalid JSON in register request", e);
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write(
                    ResponseBuilder.error("Invalid Request",
                            "Malformed JSON in request body",
                            HttpServletResponse.SC_BAD_REQUEST)
            );
        } catch (Exception e) {
            logger.error("Error during user registration", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(
                    ResponseBuilder.error("Registration Failed",
                            e.getMessage(),
                            HttpServletResponse.SC_INTERNAL_SERVER_ERROR)
            );
        }
    }

    /**
     * Handle user logout
     * POST /api/user/logout
     */
    private void handleLogout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String username = SessionManager.getCurrentUsername(request);
        long sessionDuration = SessionManager.getSessionDuration(request);

        // Logout from UserService
        userService.logout();

        // Invalidate session
        SessionManager.invalidateSession(request);

        logger.info("User logged out: {} (Session duration: {} min)", username, sessionDuration);

        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().write(
                ResponseBuilder.success("Logout successful")
        );
    }

    /**
     * Get current user profile
     * GET /api/user/profile
     */
    private void handleGetProfile(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        User user = SessionManager.getCurrentUser(request);

        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(
                    ResponseBuilder.error("Unauthorized",
                            "User not logged in",
                            HttpServletResponse.SC_UNAUTHORIZED)
            );
            return;
        }

        UserResponse userResponse = new UserResponse(
                user.getId().getValue(),
                user.getUsername(),
                user.getEmail(),
                user.getRole().name()
        );

        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().write(
                ResponseBuilder.success("User profile retrieved", userResponse)
        );
    }

    /**
     * Get session information
     * GET /api/user/session-info
     */
    private void handleGetSessionInfo(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        if (!SessionManager.isUserLoggedIn(request)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(
                    ResponseBuilder.error("Unauthorized",
                            "No active session",
                            HttpServletResponse.SC_UNAUTHORIZED)
            );
            return;
        }

        Map<String, Object> sessionInfo = new HashMap<>();
        sessionInfo.put("username", SessionManager.getCurrentUsername(request));
        sessionInfo.put("role", SessionManager.getCurrentUserRole(request).name());
        sessionInfo.put("loginTime", SessionManager.getLoginTime(request));
        sessionInfo.put("sessionDuration", SessionManager.getSessionDuration(request) + " minutes");
        sessionInfo.put("aboutToExpire", SessionManager.isSessionAboutToExpire(request));

        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().write(
                ResponseBuilder.success("Session information retrieved", sessionInfo)
        );
    }

    /**
     * Validate login request
     */
    private Map<String, String> validateLoginRequest(LoginRequest request) {
        Map<String, String> errors = new HashMap<>();

        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            errors.put("username", "Username is required");
        }

        if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
            errors.put("password", "Password is required");
        }

        return errors;
    }

    /**
     * Validate register request
     */
    private Map<String, String> validateRegisterRequest(RegisterRequest request) {
        Map<String, String> errors = new HashMap<>();

        if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            errors.put("username", "Username is required");
        } else if (request.getUsername().length() < 3) {
            errors.put("username", "Username must be at least 3 characters");
        }

        if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
            errors.put("email", "Email is required");
        } else if (!request.getEmail().matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            errors.put("email", "Invalid email format");
        }

        if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
            errors.put("password", "Password is required");
        } else if (request.getPassword().length() < 6) {
            errors.put("password", "Password must be at least 6 characters");
        }

        if (request.getRole() == null || request.getRole().trim().isEmpty()) {
            errors.put("role", "Role is required");
        } else {
            try {
                UserRole.valueOf(request.getRole());
            } catch (IllegalArgumentException e) {
                errors.put("role", "Invalid role. Must be ADMIN, MANAGER, or CASHIER");
            }
        }

        return errors;
    }

    /**
     * Send error response
     */
    private void sendError(HttpServletResponse response, String message, int statusCode)
            throws IOException {
        response.setStatus(statusCode);
        response.getWriter().write(
                ResponseBuilder.error("Error", message, statusCode)
        );
    }
}