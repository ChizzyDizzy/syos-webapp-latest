<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.syos.domain.entities.User" %>
<%@ page import="com.syos.domain.valueobjects.UserRole" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/views/auth/login.jsp");
        return;
    }
    UserRole role = currentUser.getRole();

    // Only admins can access user management
    if (role != UserRole.ADMIN) {
        response.sendRedirect(request.getContextPath() + "/views/sales/dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - User Management</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="dashboard-container">
    <aside class="sidebar">
        <div class="sidebar-header">
            <h2>🏪 SYOS POS</h2>
            <div class="user-info">
                <p class="user-name"><%= currentUser.getUsername() %></p>
                <p class="user-role"><%= role %></p>
            </div>
        </div>

        <nav class="sidebar-nav">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="nav-link">
                <span class="nav-icon">💰</span>
                <span>Sales</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Inventory</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📈</span>
                <span>Reports</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/user/management.jsp" class="nav-link active">
                <span class="nav-icon">👥</span>
                <span>User Management</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/user/profile.jsp" class="nav-link">
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
            <h1>User Management</h1>
            <div class="header-actions">
                <button class="btn btn-primary" onclick="showCreateUserModal()">
                    👥 Create New User
                </button>
            </div>
        </header>

        <div class="content-body">
            <!-- User Statistics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Users</h3>
                    <p class="stat-value" id="total-users">0</p>
                    <p class="stat-label">Registered Users</p>
                </div>
                <div class="stat-card">
                    <h3>Active Today</h3>
                    <p class="stat-value" id="active-today">0</p>
                    <p class="stat-label">Users Active</p>
                </div>
                <div class="stat-card">
                    <h3>Admins</h3>
                    <p class="stat-value" id="admin-count">0</p>
                    <p class="stat-label">Administrators</p>
                </div>
                <div class="stat-card">
                    <h3>Cashiers</h3>
                    <p class="stat-value" id="cashier-count">0</p>
                    <p class="stat-label">Cashier Accounts</p>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="table-container">
                <h2>Quick User Management</h2>
                <div class="action-grid">
                    <div class="action-card" onclick="showCreateUserModal()">
                        <span class="action-icon">➕</span>
                        <h3>Create User</h3>
                        <p>Register new system user</p>
                    </div>

                    <div class="action-card" onclick="showBulkImportModal()">
                        <span class="action-icon">📥</span>
                        <h3>Bulk Import</h3>
                        <p>Import multiple users</p>
                    </div>

                    <div class="action-card" onclick="exportUserList()">
                        <span class="action-icon">📤</span>
                        <h3>Export Users</h3>
                        <p>Download user list</p>
                    </div>

                    <div class="action-card" onclick="showAuditLog()">
                        <span class="action-icon">📋</span>
                        <h3>Audit Log</h3>
                        <p>View user activities</p>
                    </div>
                </div>
            </div>

            <!-- Users Table -->
            <div class="table-container">
                <h3>All System Users</h3>
                <div class="section-header">
                    <div>
                        <input type="text" id="search-users" class="form-control"
                               placeholder="Search users..." style="width: 300px;">
                    </div>
                    <div>
                        <select id="role-filter" class="form-control" onchange="filterUsers()" style="width: 200px;">
                            <option value="all">All Roles</option>
                            <option value="ADMIN">Admins</option>
                            <option value="MANAGER">Managers</option>
                            <option value="CASHIER">Cashiers</option>
                        </select>
                    </div>
                </div>

                <table class="data-table" id="users-table">
                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Last Login</th>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="users-body">
                    <tr><td colspan="8">Loading users...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- User Activity Chart -->
            <div class="table-container">
                <h3>User Activity Overview</h3>
                <div id="activity-chart" style="height: 200px; background: var(--bg-color); border-radius: var(--border-radius); padding: 20px;">
                    <p class="text-center text-muted">User activity chart would be displayed here</p>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- Create User Modal -->
<div id="create-user-modal" class="modal" style="display: none;">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Create New User</h2>
            <button class="modal-close" onclick="closeModal('create-user-modal')">&times;</button>
        </div>
        <div class="modal-body">
            <form id="create-user-form">
                <div class="form-group">
                    <label for="new-username">Username *</label>
                    <input type="text" id="new-username" class="form-control" required
                           placeholder="Enter username">
                </div>

                <div class="form-group">
                    <label for="new-email">Email Address</label>
                    <input type="email" id="new-email" class="form-control"
                           placeholder="Enter email address">
                </div>

                <div class="form-group">
                    <label for="new-password">Password *</label>
                    <input type="password" id="new-password" class="form-control" required
                           placeholder="Enter password">
                </div>

                <div class="form-group">
                    <label for="confirm-password">Confirm Password *</label>
                    <input type="password" id="confirm-password" class="form-control" required
                           placeholder="Confirm password">
                </div>

                <div class="form-group">
                    <label for="user-role">Role *</label>
                    <select id="user-role" class="form-control" required>
                        <option value="">Select Role</option>
                        <option value="CASHIER">Cashier</option>
                        <option value="MANAGER">Manager</option>
                        <option value="ADMIN">Administrator</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>
                        <input type="checkbox" id="send-welcome-email">
                        Send welcome email with login instructions
                    </label>
                </div>
            </form>
        </div>
        <div class="modal-footer">
            <button class="btn btn-secondary" onclick="closeModal('create-user-modal')">Cancel</button>
            <button class="btn btn-primary" onclick="createUser()">Create User</button>
        </div>
    </div>
</div>

<!-- Edit User Modal -->
<div id="edit-user-modal" class="modal" style="display: none;">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Edit User</h2>
            <button class="modal-close" onclick="closeModal('edit-user-modal')">&times;</button>
        </div>
        <div class="modal-body">
            <form id="edit-user-form">
                <input type="hidden" id="edit-user-id">
                <div class="form-group">
                    <label for="edit-username">Username</label>
                    <input type="text" id="edit-username" class="form-control" readonly>
                </div>

                <div class="form-group">
                    <label for="edit-email">Email Address</label>
                    <input type="email" id="edit-email" class="form-control">
                </div>

                <div class="form-group">
                    <label for="edit-role">Role</label>
                    <select id="edit-role" class="form-control">
                        <option value="CASHIER">Cashier</option>
                        <option value="MANAGER">Manager</option>
                        <option value="ADMIN">Administrator</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="edit-status">Status</label>
                    <select id="edit-status" class="form-control">
                        <option value="ACTIVE">Active</option>
                        <option value="INACTIVE">Inactive</option>
                        <option value="SUSPENDED">Suspended</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="reset-password">Reset Password</label>
                    <input type="password" id="reset-password" class="form-control"
                           placeholder="Leave blank to keep current password">
                </div>
            </form>
        </div>
        <div class="modal-footer">
            <button class="btn btn-secondary" onclick="closeModal('edit-user-modal')">Cancel</button>
            <button class="btn btn-primary" onclick="updateUser()">Update User</button>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let allUsers = [];

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadUserManagementData();

        // Setup search
        document.getElementById('search-users').addEventListener('input', function(e) {
            filterUsers();
        });
    });

    async function loadUserManagementData() {
        await loadUserStatistics();
        await loadAllUsers();
    }

    async function loadUserStatistics() {
        try {
            // This would normally come from a dedicated API endpoint
            const users = await apiRequest('/user/list'); // This endpoint doesn't exist yet

            // For demo, we'll create sample data
            const sampleUsers = [
                { id: 1, username: 'admin', role: 'ADMIN', lastLogin: new Date(), status: 'ACTIVE', created: new Date() },
                { id: 2, username: 'manager', role: 'MANAGER', lastLogin: new Date(), status: 'ACTIVE', created: new Date() },
                { id: 3, username: 'cashier1', role: 'CASHIER', lastLogin: new Date(), status: 'ACTIVE', created: new Date() },
                { id: 4, username: 'cashier2', role: 'CASHIER', lastLogin: null, status: 'INACTIVE', created: new Date() }
            ];

            const totalUsers = sampleUsers.length;
            const activeToday = sampleUsers.filter(user =>
                user.lastLogin && isToday(user.lastLogin)
            ).length;
            const adminCount = sampleUsers.filter(user => user.role === 'ADMIN').length;
            const cashierCount = sampleUsers.filter(user => user.role === 'CASHIER').length;

            document.getElementById('total-users').textContent = totalUsers;
            document.getElementById('active-today').textContent = activeToday;
            document.getElementById('admin-count').textContent = adminCount;
            document.getElementById('cashier-count').textContent = cashierCount;

        } catch (error) {
            console.error('Failed to load user statistics:', error);
        }
    }

    async function loadAllUsers() {
        const tbody = document.getElementById('users-body');

        try {
            // This would normally come from a dedicated API endpoint
            // const response = await apiRequest('/user/list');

            // For demo, we'll use sample data
            allUsers = [
                {
                    id: 1,
                    username: 'admin',
                    email: 'admin@syos.com',
                    role: 'ADMIN',
                    lastLogin: new Date().toISOString(),
                    status: 'ACTIVE',
                    created: new Date('2024-01-01').toISOString()
                },
                {
                    id: 2,
                    username: 'manager',
                    email: 'manager@syos.com',
                    role: 'MANAGER',
                    lastLogin: new Date().toISOString(),
                    status: 'ACTIVE',
                    created: new Date('2024-02-01').toISOString()
                },
                {
                    id: 3,
                    username: 'cashier1',
                    email: 'cashier1@syos.com',
                    role: 'CASHIER',
                    lastLogin: new Date().toISOString(),
                    status: 'ACTIVE',
                    created: new Date('2024-03-01').toISOString()
                },
                {
                    id: 4,
                    username: 'cashier2',
                    email: 'cashier2@syos.com',
                    role: 'CASHIER',
                    lastLogin: null,
                    status: 'INACTIVE',
                    created: new Date('2024-03-15').toISOString()
                }
            ];

            displayUsers(allUsers);
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="8" class="text-center">Error loading users: ${error.message}</td></tr>`;
        }
    }

    function displayUsers(users) {
        const tbody = document.getElementById('users-body');

        if (users.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">No users found</td></tr>';
            return;
        }

        tbody.innerHTML = users.map(user => {
            const lastLogin = user.lastLogin ?
                new Date(user.lastLogin).toLocaleDateString() : 'Never';
            const created = new Date(user.created).toLocaleDateString();
            const statusBadge = getStatusBadge(user.status);
            const roleBadge = getRoleBadge(user.role);

            return `
                    <tr>
                        <td>${user.id}</td>
                        <td><strong>${user.username}</strong></td>
                        <td>${user.email || 'Not set'}</td>
                        <td>${roleBadge}</td>
                        <td>${lastLogin}</td>
                        <td>${statusBadge}</td>
                        <td>${created}</td>
                        <td>
                            <button class="btn btn-secondary" onclick="editUser(${user.id})">
                                Edit
                            </button>
                            <button class="btn btn-danger" onclick="deleteUser(${user.id}, '${user.username}')">
                                Delete
                            </button>
                        </td>
                    </tr>
                `;
        }).join('');
    }

    function getStatusBadge(status) {
        const badges = {
            'ACTIVE': '<span class="badge badge-success">Active</span>',
            'INACTIVE': '<span class="badge badge-secondary">Inactive</span>',
            'SUSPENDED': '<span class="badge badge-danger">Suspended</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">' + status + '</span>';
    }

    function getRoleBadge(role) {
        const badges = {
            'ADMIN': '<span class="badge badge-danger">Admin</span>',
            'MANAGER': '<span class="badge badge-warning">Manager</span>',
            'CASHIER': '<span class="badge badge-info">Cashier</span>'
        };
        return badges[role] || '<span class="badge badge-secondary">' + role + '</span>';
    }

    function filterUsers() {
        const searchTerm = document.getElementById('search-users').value.toLowerCase();
        const roleFilter = document.getElementById('role-filter').value;

        let filteredUsers = allUsers;

        // Apply role filter
        if (roleFilter !== 'all') {
            filteredUsers = filteredUsers.filter(user => user.role === roleFilter);
        }

        // Apply search filter
        if (searchTerm) {
            filteredUsers = filteredUsers.filter(user =>
                user.username.toLowerCase().includes(searchTerm) ||
                (user.email && user.email.toLowerCase().includes(searchTerm))
            );
        }

        displayUsers(filteredUsers);
    }

    function showCreateUserModal() {
        document.getElementById('create-user-modal').style.display = 'flex';
        // Reset form
        document.getElementById('create-user-form').reset();
    }

    function showBulkImportModal() {
        showAlert('info', 'Bulk import feature would be implemented here');
    }

    function showAuditLog() {
        showAlert('info', 'Audit log feature would be implemented here');
    }

    async function createUser() {
        const formData = {
            username: document.getElementById('new-username').value,
            email: document.getElementById('new-email').value,
            password: document.getElementById('new-password').value,
            role: document.getElementById('user-role').value,
            sendWelcomeEmail: document.getElementById('send-welcome-email').checked
        };

        // Validate passwords match
        if (formData.password !== document.getElementById('confirm-password').value) {
            showAlert('error', 'Passwords do not match');
            return;
        }

        try {
            const response = await apiRequest('/user/register', {
                method: 'POST',
                body: JSON.stringify(formData)
            });

            if (response.success) {
                showAlert('success', `User ${formData.username} created successfully`);
                closeModal('create-user-modal');
                loadUserManagementData(); // Refresh the list
            } else {
                showAlert('error', response.message || 'Failed to create user');
            }
        } catch (error) {
            showAlert('error', `Failed to create user: ${error.message}`);
        }
    }

    function editUser(userId) {
        const user = allUsers.find(u => u.id === userId);
        if (!user) return;

        document.getElementById('edit-user-id').value = user.id;
        document.getElementById('edit-username').value = user.username;
        document.getElementById('edit-email').value = user.email || '';
        document.getElementById('edit-role').value = user.role;
        document.getElementById('edit-status').value = user.status;
        document.getElementById('reset-password').value = '';

        document.getElementById('edit-user-modal').style.display = 'flex';
    }

    async function updateUser() {
        const userId = document.getElementById('edit-user-id').value;
        const formData = {
            email: document.getElementById('edit-email').value,
            role: document.getElementById('edit-role').value,
            status: document.getElementById('edit-status').value
        };

        const newPassword = document.getElementById('reset-password').value;
        if (newPassword) {
            formData.password = newPassword;
        }

        try {
            const response = await apiRequest(`/user/${userId}`, {
                method: 'PUT',
                body: JSON.stringify(formData)
            });

            if (response.success) {
                showAlert('success', `User updated successfully`);
                closeModal('edit-user-modal');
                loadUserManagementData(); // Refresh the list
            } else {
                showAlert('error', response.message || 'Failed to update user');
            }
        } catch (error) {
            showAlert('error', `Failed to update user: ${error.message}`);
        }
    }

    function deleteUser(userId, username) {
        if (confirm(`Are you sure you want to delete user "${username}"? This action cannot be undone.`)) {
            // This would call the delete API
            showAlert('warning', `Delete user feature would delete user: ${username}`);

            // Simulate API call
            setTimeout(() => {
                showAlert('success', `User ${username} deleted successfully`);
                loadUserManagementData(); // Refresh the list
            }, 1000);
        }
    }

    function exportUserList() {
        const headers = ['ID', 'Username', 'Email', 'Role', 'Last Login', 'Status', 'Created Date'];
        const csvContent = [
            headers.join(','),
            ...allUsers.map(user => [
                user.id,
                `"${user.username}"`,
                `"${user.email || ''}"`,
                user.role,
                user.lastLogin ? new Date(user.lastLogin).toLocaleDateString() : 'Never',
                user.status,
                new Date(user.created).toLocaleDateString()
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `users-export-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);

        showAlert('success', 'User list exported successfully');
    }

    function closeModal(modalId) {
        document.getElementById(modalId).style.display = 'none';
    }

    function isToday(date) {
        const today = new Date();
        return new Date(date).toDateString() === today.toDateString();
    }

    // Password confirmation validation
    document.getElementById('confirm-password').addEventListener('input', function() {
        const password = document.getElementById('new-password').value;
        const confirm = this.value;

        if (password !== confirm) {
            this.setCustomValidity('Passwords do not match');
        } else {
            this.setCustomValidity('');
        }
    });
</script>
</body>
</html>