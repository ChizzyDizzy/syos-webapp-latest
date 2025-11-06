<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.syos.domain.entities.User" %>
<%@ page import="com.syos.domain.valueobjects.UserRole" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/views/auth/login.jsp");
        return;
    }
    String username = currentUser.getUsername();
    UserRole role = currentUser.getRole();
    String email = currentUser.getEmail() != null ? currentUser.getEmail() : "Not set";
    String lastLogin = currentUser.getLastLogin() != null ?
            new java.text.SimpleDateFormat("MMM dd, yyyy HH:mm").format(currentUser.getLastLogin()) : "Never";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - User Profile</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="dashboard-container">
    <aside class="sidebar">
        <div class="sidebar-header">
            <h2>🏪 SYOS POS</h2>
            <div class="user-info">
                <p class="user-name"><%= username %></p>
                <p class="user-role"><%= role %></p>
            </div>
        </div>

        <nav class="sidebar-nav">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="nav-link">
                <span class="nav-icon">💰</span>
                <span>Sales Dashboard</span>
            </a>

            <% if (role == UserRole.MANAGER || role == UserRole.ADMIN) { %>
            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Inventory</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📈</span>
                <span>Reports</span>
            </a>
            <% } %>

            <% if (role == UserRole.ADMIN) { %>
            <a href="${pageContext.request.contextPath}/views/user/management.jsp" class="nav-link">
                <span class="nav-icon">👥</span>
                <span>User Management</span>
            </a>
            <% } %>

            <a href="${pageContext.request.contextPath}/views/user/profile.jsp" class="nav-link active">
                <span class="nav-icon">👤</span>
                <span>My Profile</span>
            </a>
        </nav>

        <div class="sidebar-footer">
            <button id="logout-btn" class="btn btn-danger btn-block">🚪 Logout</button>
        </div>
    </aside>

    <main class="main-content">
        <header class="content-header">
            <h1>User Profile</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Profile Overview -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>User Role</h3>
                    <p class="stat-value" id="user-role"><%= role %></p>
                    <p class="stat-label">Access Level</p>
                </div>
                <div class="stat-card">
                    <h3>Last Login</h3>
                    <p class="stat-value" id="last-login"><%= lastLogin %></p>
                    <p class="stat-label">Previous Access</p>
                </div>
                <div class="stat-card">
                    <h3>Account Status</h3>
                    <p class="stat-value" id="account-status">Active</p>
                    <p class="stat-label">Current Status</p>
                </div>
                <div class="stat-card">
                    <h3>Session Time</h3>
                    <p class="stat-value" id="session-time">0m</p>
                    <p class="stat-label">Current Session</p>
                </div>
            </div>

            <!-- Profile Information -->
            <div class="table-container">
                <h2>Profile Information</h2>

                <div class="profile-section">
                    <div class="profile-header">
                        <div class="avatar">
                            <span class="avatar-icon">👤</span>
                        </div>
                        <div class="profile-info">
                            <h3><%= username %></h3>
                            <p class="profile-role"><%= role %></p>
                            <p class="profile-email"><%= email %></p>
                        </div>
                    </div>

                    <form id="profile-form" class="profile-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label for="username">Username</label>
                                <input type="text" id="username" class="form-control"
                                       value="<%= username %>" readonly>
                                <small class="text-muted">Username cannot be changed</small>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address</label>
                                <input type="email" id="email" class="form-control"
                                       value="<%= email %>" placeholder="Enter email address">
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="current-password">Current Password</label>
                                <input type="password" id="current-password" class="form-control"
                                       placeholder="Enter current password">
                            </div>

                            <div class="form-group">
                                <label for="new-password">New Password</label>
                                <input type="password" id="new-password" class="form-control"
                                       placeholder="Enter new password">
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="confirm-password">Confirm New Password</label>
                            <input type="password" id="confirm-password" class="form-control"
                                   placeholder="Confirm new password">
                        </div>

                        <div class="form-group">
                            <button type="submit" class="btn btn-primary">
                                Update Profile
                            </button>
                            <button type="button" class="btn btn-secondary" onclick="resetForm()">
                                Reset Changes
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Account Statistics -->
            <div class="table-container">
                <h3>Account Statistics</h3>
                <div class="stats-cards">
                    <div class="stat-card-small">
                        <h4>📊 Total Sales</h4>
                        <p class="stat-number" id="total-sales">0</p>
                        <p class="stat-label">Transactions</p>
                    </div>
                    <div class="stat-card-small">
                        <h4>💰 Total Revenue</h4>
                        <p class="stat-number" id="total-revenue">$0.00</p>
                        <p class="stat-label">Generated</p>
                    </div>
                    <div class="stat-card-small">
                        <h4>📦 Stock Added</h4>
                        <p class="stat-number" id="stock-added">0</p>
                        <p class="stat-label">Items</p>
                    </div>
                    <div class="stat-card-small">
                        <h4>📈 Reports Generated</h4>
                        <p class="stat-number" id="reports-generated">0</p>
                        <p class="stat-label">This Month</p>
                    </div>
                </div>
            </div>

            <!-- Recent Activity -->
            <div class="table-container">
                <h3>Recent Activity</h3>
                <table class="data-table" id="activity-table">
                    <thead>
                    <tr>
                        <th>Time</th>
                        <th>Activity</th>
                        <th>Details</th>
                        <th>IP Address</th>
                    </tr>
                    </thead>
                    <tbody id="activity-body">
                    <tr>
                        <td><%= new java.util.Date().toString() %></td>
                        <td>Profile Viewed</td>
                        <td>User accessed profile page</td>
                        <td>127.0.0.1</td>
                    </tr>
                    </tbody>
                </table>
            </div>

            <!-- Security Settings -->
            <div class="table-container">
                <h3>Security Settings</h3>
                <div class="security-settings">
                    <div class="security-item">
                        <div class="security-info">
                            <h4>🔐 Two-Factor Authentication</h4>
                            <p>Add an extra layer of security to your account</p>
                        </div>
                        <div class="security-action">
                            <label class="switch">
                                <input type="checkbox" id="two-factor">
                                <span class="slider"></span>
                            </label>
                        </div>
                    </div>

                    <div class="security-item">
                        <div class="security-info">
                            <h4>📧 Email Notifications</h4>
                            <p>Receive important system notifications via email</p>
                        </div>
                        <div class="security-action">
                            <label class="switch">
                                <input type="checkbox" id="email-notifications" checked>
                                <span class="slider"></span>
                            </label>
                        </div>
                    </div>

                    <div class="security-item">
                        <div class="security-info">
                            <h4>📱 Session Timeout</h4>
                            <p>Automatically logout after 30 minutes of inactivity</p>
                        </div>
                        <div class="security-action">
                            <span class="badge badge-info">30 min</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Danger Zone -->
            <div class="table-container danger-zone">
                <h3>⚠️ Danger Zone</h3>
                <div class="danger-actions">
                    <div class="danger-item">
                        <div class="danger-info">
                            <h4>🗑️ Delete Account</h4>
                            <p>Permanently delete your account and all associated data</p>
                        </div>
                        <div class="danger-action">
                            <button class="btn btn-danger" onclick="showDeleteAccountModal()">
                                Delete Account
                            </button>
                        </div>
                    </div>

                    <div class="danger-item">
                        <div class="danger-info">
                            <h4>🔐 Reset All Settings</h4>
                            <p>Reset all your preferences to default values</p>
                        </div>
                        <div class="danger-action">
                            <button class="btn btn-warning" onclick="showResetSettingsModal()">
                                Reset Settings
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- Delete Account Modal -->
<div id="delete-account-modal" class="modal" style="display: none;">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Delete Account</h2>
            <button class="modal-close" onclick="closeModal('delete-account-modal')">&times;</button>
        </div>
        <div class="modal-body">
            <div class="alert alert-danger">
                <strong>Warning:</strong> This action cannot be undone. All your data will be permanently deleted.
            </div>
            <p>Please type your username to confirm:</p>
            <input type="text" id="confirm-username" class="form-control" placeholder="Enter your username">
            <p class="text-muted">Type: <strong><%= username %></strong> to confirm deletion</p>
        </div>
        <div class="modal-footer">
            <button class="btn btn-secondary" onclick="closeModal('delete-account-modal')">Cancel</button>
            <button class="btn btn-danger" onclick="deleteAccount()" disabled id="confirm-delete">
                Delete Account
            </button>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let sessionStartTime = new Date();
    let sessionTimer;

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        startSessionTimer();
        loadProfileStatistics();
        setupFormValidation();
        setupDeleteConfirmation();
    });

    function startSessionTimer() {
        sessionTimer = setInterval(updateSessionTime, 1000);
    }

    function updateSessionTime() {
        const now = new Date();
        const diff = Math.floor((now - sessionStartTime) / 1000); // in seconds
        const minutes = Math.floor(diff / 60);
        const seconds = diff % 60;

        document.getElementById('session-time').textContent =
            `${minutes}m ${seconds.toString().padStart(2, '0')}s`;
    }

    async function loadProfileStatistics() {
        try {
            // Load user-specific statistics
            const todayBills = await apiRequest('/sales/today');
            if (todayBills.success && todayBills.data) {
                // For demo purposes, we'll assume all today's bills are by current user
                document.getElementById('total-sales').textContent = todayBills.data.length;

                const totalRevenue = todayBills.data.reduce((sum, bill) => sum + bill.totalAmount, 0);
                document.getElementById('total-revenue').textContent = `$${totalRevenue.toFixed(2)}`;
            }

            // Load inventory stats (items added by user)
            const inventoryStats = await apiRequest('/inventory/statistics');
            if (inventoryStats.success && inventoryStats.data) {
                document.getElementById('stock-added').textContent =
                    inventoryStats.data.totalItems || '0';
            }

            // Reports generated (this would normally come from an API)
            document.getElementById('reports-generated').textContent = '3';

        } catch (error) {
            console.error('Failed to load profile statistics:', error);
        }
    }

    function setupFormValidation() {
        const profileForm = document.getElementById('profile-form');
        const newPassword = document.getElementById('new-password');
        const confirmPassword = document.getElementById('confirm-password');

        // Password confirmation validation
        confirmPassword.addEventListener('input', function() {
            if (newPassword.value !== confirmPassword.value) {
                confirmPassword.setCustomValidity('Passwords do not match');
            } else {
                confirmPassword.setCustomValidity('');
            }
        });

        profileForm.addEventListener('submit', async function(e) {
            e.preventDefault();

            const formData = {
                email: document.getElementById('email').value,
                currentPassword: document.getElementById('current-password').value,
                newPassword: document.getElementById('new-password').value
            };

            // Only include password fields if they're filled
            if (!formData.currentPassword && formData.newPassword) {
                showAlert('error', 'Please enter your current password to change password');
                return;
            }

            try {
                const response = await apiRequest('/user/profile', {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });

                if (response.success) {
                    showAlert('success', 'Profile updated successfully');
                    // Clear password fields
                    document.getElementById('current-password').value = '';
                    document.getElementById('new-password').value = '';
                    document.getElementById('confirm-password').value = '';
                } else {
                    showAlert('error', response.message || 'Failed to update profile');
                }
            } catch (error) {
                showAlert('error', `Failed to update profile: ${error.message}`);
            }
        });
    }

    function resetForm() {
        document.getElementById('profile-form').reset();
        document.getElementById('email').value = '<%= email %>';
        showAlert('info', 'Form reset to original values');
    }

    function setupDeleteConfirmation() {
        const confirmInput = document.getElementById('confirm-username');
        const confirmButton = document.getElementById('confirm-delete');

        confirmInput.addEventListener('input', function() {
            confirmButton.disabled = this.value !== '<%= username %>';
        });
    }

    function showDeleteAccountModal() {
        document.getElementById('delete-account-modal').style.display = 'flex';
    }

    function showResetSettingsModal() {
        if (confirm('Are you sure you want to reset all settings to default? This cannot be undone.')) {
            // Reset settings logic would go here
            showAlert('info', 'Settings reset feature would be implemented here');
        }
    }

    function closeModal(modalId) {
        document.getElementById(modalId).style.display = 'none';
        // Reset confirmation input
        document.getElementById('confirm-username').value = '';
        document.getElementById('confirm-delete').disabled = true;
    }

    async function deleteAccount() {
        try {
            const response = await apiRequest('/user/profile', {
                method: 'DELETE'
            });

            if (response.success) {
                showAlert('success', 'Account deleted successfully');
                // Logout and redirect
                setTimeout(() => {
                    handleLogout();
                }, 2000);
            } else {
                showAlert('error', response.message || 'Failed to delete account');
            }
        } catch (error) {
            showAlert('error', `Failed to delete account: ${error.message}`);
        }
    }

    // Clean up timer when leaving page
    window.addEventListener('beforeunload', function() {
        if (sessionTimer) {
            clearInterval(sessionTimer);
        }
    });

    // Add custom CSS for profile page
    const style = document.createElement('style');
    style.textContent = `
            .profile-section {
                padding: 20px 0;
            }
            .profile-header {
                display: flex;
                align-items: center;
                margin-bottom: 30px;
                padding-bottom: 20px;
                border-bottom: 1px solid var(--border-color);
            }
            .avatar {
                width: 80px;
                height: 80px;
                border-radius: 50%;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                display: flex;
                align-items: center;
                justify-content: center;
                margin-right: 20px;
            }
            .avatar-icon {
                font-size: 2.5rem;
            }
            .profile-info h3 {
                margin: 0 0 5px 0;
                font-size: 1.5rem;
            }
            .profile-role {
                color: var(--primary-color);
                font-weight: 600;
                margin: 0 0 5px 0;
            }
            .profile-email {
                color: var(--text-secondary);
                margin: 0;
            }
            .form-row {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
            }
            @media (max-width: 768px) {
                .form-row {
                    grid-template-columns: 1fr;
                }
            }
            .stats-cards {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                margin-top: 15px;
            }
            .stat-card-small {
                background: var(--card-bg);
                padding: 15px;
                border-radius: var(--border-radius);
                text-align: center;
                border: 1px solid var(--border-color);
            }
            .stat-card-small h4 {
                margin: 0 0 10px 0;
                font-size: 0.9rem;
                color: var(--text-secondary);
            }
            .stat-number {
                font-size: 1.5rem;
                font-weight: 700;
                color: var(--primary-color);
                margin: 0;
            }
            .security-settings {
                margin-top: 15px;
            }
            .security-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 15px 0;
                border-bottom: 1px solid var(--border-color);
            }
            .security-item:last-child {
                border-bottom: none;
            }
            .security-info h4 {
                margin: 0 0 5px 0;
            }
            .security-info p {
                margin: 0;
                color: var(--text-secondary);
                font-size: 0.9rem;
            }
            .switch {
                position: relative;
                display: inline-block;
                width: 50px;
                height: 24px;
            }
            .switch input {
                opacity: 0;
                width: 0;
                height: 0;
            }
            .slider {
                position: absolute;
                cursor: pointer;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: #ccc;
                transition: .4s;
                border-radius: 24px;
            }
            .slider:before {
                position: absolute;
                content: "";
                height: 16px;
                width: 16px;
                left: 4px;
                bottom: 4px;
                background-color: white;
                transition: .4s;
                border-radius: 50%;
            }
            input:checked + .slider {
                background-color: var(--primary-color);
            }
            input:checked + .slider:before {
                transform: translateX(26px);
            }
            .danger-zone {
                border-left: 4px solid var(--danger-color);
            }
            .danger-actions {
                margin-top: 15px;
            }
            .danger-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 15px 0;
                border-bottom: 1px solid var(--border-color);
            }
            .danger-item:last-child {
                border-bottom: none;
            }
            .danger-info h4 {
                margin: 0 0 5px 0;
                color: var(--danger-color);
            }
            .danger-info p {
                margin: 0;
                color: var(--text-secondary);
                font-size: 0.9rem;
            }
        `;
    document.head.appendChild(style);
</script>
</body>
</html>