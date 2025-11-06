package com.syos.web.dto;

/**
 * Data Transfer Object for user registration requests
 */
public class RegisterRequest {
    private String username;
    private String email;
    private String password;
    private String role; // ADMIN, MANAGER, CASHIER

    // Default constructor for JSON deserialization
    public RegisterRequest() {
    }

    public RegisterRequest(String username, String email, String password, String role) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.role = role;
    }

    // Getters and Setters
    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    // Validation
    public boolean isValid() {
        return username != null && !username.trim().isEmpty() &&
                email != null && !email.trim().isEmpty() && isValidEmail(email) &&
                password != null && password.length() >= 6 &&
                role != null && isValidRole(role);
    }

    private boolean isValidEmail(String email) {
        return email.matches("^[A-Za-z0-9+_.-]+@(.+)$");
    }

    private boolean isValidRole(String role) {
        return role.equals("ADMIN") || role.equals("MANAGER") || role.equals("CASHIER");
    }

    public String getValidationErrors() {
        StringBuilder errors = new StringBuilder();

        if (username == null || username.trim().isEmpty()) {
            errors.append("Username is required. ");
        }
        if (email == null || email.trim().isEmpty()) {
            errors.append("Email is required. ");
        } else if (!isValidEmail(email)) {
            errors.append("Invalid email format. ");
        }
        if (password == null || password.length() < 6) {
            errors.append("Password must be at least 6 characters. ");
        }
        if (role == null || !isValidRole(role)) {
            errors.append("Role must be ADMIN, MANAGER, or CASHIER. ");
        }

        return errors.toString().trim();
    }

    @Override
    public String toString() {
        return "RegisterRequest{username='" + username + "', email='" + email + "', role='" + role + "'}";
    }
}