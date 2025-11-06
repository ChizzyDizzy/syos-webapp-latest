package com.syos.web.dto;

import java.time.LocalDateTime;

/**
 * Data Transfer Object for user responses
 * Used to send user information to the client (without sensitive data like password)
 */
public class UserResponse {
    private Long id;
    private String username;
    private String email;
    private String role;
    private LocalDateTime createdAt;
    private LocalDateTime lastLoginAt;

    // Permissions flags
    private boolean canProcessSales;
    private boolean canManageInventory;
    private boolean canViewReports;
    private boolean canManageUsers;

    // Default constructor for JSON serialization
    public UserResponse() {
    }

    // ADDED: Missing constructor that was causing compilation error
    public UserResponse(Long id, String username, String email, String role) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.role = role;
        this.setPermissionsBasedOnRole(role);
    }

    public UserResponse(Long id, String username, String email, String role,
                        LocalDateTime createdAt, LocalDateTime lastLoginAt) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.role = role;
        this.createdAt = createdAt;
        this.lastLoginAt = lastLoginAt;
        this.setPermissionsBasedOnRole(role);
    }

    private void setPermissionsBasedOnRole(String role) {
        switch (role) {
            case "ADMIN":
                this.canProcessSales = true;
                this.canManageInventory = true;
                this.canViewReports = true;
                this.canManageUsers = true;
                break;
            case "MANAGER":
                this.canProcessSales = true;
                this.canManageInventory = true;
                this.canViewReports = true;
                this.canManageUsers = false;
                break;
            case "CASHIER":
                this.canProcessSales = true;
                this.canManageInventory = false;
                this.canViewReports = false;
                this.canManageUsers = false;
                break;
            default:
                this.canProcessSales = false;
                this.canManageInventory = false;
                this.canViewReports = false;
                this.canManageUsers = false;
        }
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

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

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
        this.setPermissionsBasedOnRole(role);
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getLastLoginAt() {
        return lastLoginAt;
    }

    public void setLastLoginAt(LocalDateTime lastLoginAt) {
        this.lastLoginAt = lastLoginAt;
    }

    public boolean isCanProcessSales() {
        return canProcessSales;
    }

    public void setCanProcessSales(boolean canProcessSales) {
        this.canProcessSales = canProcessSales;
    }

    public boolean isCanManageInventory() {
        return canManageInventory;
    }

    public void setCanManageInventory(boolean canManageInventory) {
        this.canManageInventory = canManageInventory;
    }

    public boolean isCanViewReports() {
        return canViewReports;
    }

    public void setCanViewReports(boolean canViewReports) {
        this.canViewReports = canViewReports;
    }

    public boolean isCanManageUsers() {
        return canManageUsers;
    }

    public void setCanManageUsers(boolean canManageUsers) {
        this.canManageUsers = canManageUsers;
    }

    @Override
    public String toString() {
        return "UserResponse{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", role='" + role + '\'' +
                ", createdAt=" + createdAt +
                ", lastLoginAt=" + lastLoginAt +
                '}';
    }
}