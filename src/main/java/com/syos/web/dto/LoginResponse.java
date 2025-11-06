package com.syos.web.dto;

/**
 * Data Transfer Object for login responses
 */
public class LoginResponse {
    private boolean success;
    private String message;
    private UserResponse user;
    private String sessionToken;

    // Default constructor for JSON serialization
    public LoginResponse() {
    }

    public LoginResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }

    public LoginResponse(boolean success, String message, UserResponse user, String sessionToken) {
        this.success = success;
        this.message = message;
        this.user = user;
        this.sessionToken = sessionToken;
    }

    // ADDED: Missing constructor that was causing compilation error
    public LoginResponse(Long userId, String username, String email, String role, String loginTime) {
        this.success = true;
        this.message = "Login successful";
        this.user = new UserResponse(userId, username, email, role);
        this.sessionToken = loginTime;
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public UserResponse getUser() {
        return user;
    }

    public void setUser(UserResponse user) {
        this.user = user;
    }

    public String getSessionToken() {
        return sessionToken;
    }

    public void setSessionToken(String sessionToken) {
        this.sessionToken = sessionToken;
    }

    // Factory methods for common scenarios
    public static LoginResponse success(UserResponse user, String sessionToken) {
        return new LoginResponse(true, "Login successful", user, sessionToken);
    }

    public static LoginResponse failure(String message) {
        return new LoginResponse(false, message);
    }

    @Override
    public String toString() {
        return "LoginResponse{success=" + success + ", message='" + message + "', user=" + user + "}";
    }
}