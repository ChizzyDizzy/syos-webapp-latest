package com.syos.web.dto;

/**
 * Data Transfer Object for login requests
 */
public class LoginRequest {
    private String username;
    private String password;

    // Default constructor for JSON deserialization
    public LoginRequest() {
    }

    public LoginRequest(String username, String password) {
        this.username = username;
        this.password = password;
    }

    // Getters and Setters
    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    // Validation
    public boolean isValid() {
        return username != null && !username.trim().isEmpty() &&
                password != null && !password.trim().isEmpty();
    }

    @Override
    public String toString() {
        return "LoginRequest{username='" + username + "'}"; // Don't include password in toString
    }
}