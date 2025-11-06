<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - Login</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="container">
    <div class="login-container">
        <div class="login-header">
            <h1>🏪 SYOS POS</h1>
            <p class="subtitle">Synex Outlet Store - Point of Sale System</p>
        </div>

        <form id="login-form" class="login-form">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" class="form-control" required
                       placeholder="Enter your username">
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" class="form-control" required
                       placeholder="Enter your password">
            </div>

            <button type="submit" class="btn btn-primary btn-block">
                <span id="login-text">Login</span>
                <div id="login-spinner" class="spinner" style="display: none;"></div>
            </button>
        </form>

        <div id="login-alert" class="alert" style="display: none;"></div>

        <div class="login-footer">
            <h3>Demo Credentials</h3>
            <div class="credentials-grid">
                <div class="credential-card">
                    <strong>Admin</strong>
                    <p>Username: admin</p>
                    <p>Password: admin123</p>
                </div>
                <div class="credential-card">
                    <strong>Manager</strong>
                    <p>Username: manager</p>
                    <p>Password: manager123</p>
                </div>
                <div class="credential-card">
                    <strong>Cashier</strong>
                    <p>Username: cashier</p>
                    <p>Password: cashier123</p>
                </div>
            </div>

            <div class="system-info">
                <p>System Information:</p>
                <ul>
                    <li>Version: 1.0.0</li>
                    <li>Database: MySQL</li>
                    <li>Server: Apache Tomcat</li>
                </ul>
            </div>
        </div>
    </div>
</div>

<script>
    document.getElementById('login-form').addEventListener('submit', async function(e) {
        e.preventDefault();

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const alertDiv = document.getElementById('login-alert');
        const loginText = document.getElementById('login-text');
        const loginSpinner = document.getElementById('login-spinner');

        // Show loading state
        loginText.style.display = 'none';
        loginSpinner.style.display = 'block';

        try {
            const response = await fetch('${pageContext.request.contextPath}/api/user/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ username, password })
            });

            const data = await response.json();

            if (data.success) {
                // Store user info in sessionStorage
                sessionStorage.setItem('authToken', data.data.token);
                sessionStorage.setItem('userRole', data.data.role);
                sessionStorage.setItem('username', data.data.username);

                // Redirect to dashboard
                window.location.href = '${pageContext.request.contextPath}/views/sales/dashboard.jsp';
            } else {
                showAlert(alertDiv, 'error', data.message || 'Login failed');
            }
        } catch (error) {
            showAlert(alertDiv, 'error', 'Login failed: ' + error.message);
        } finally {
            // Reset loading state
            loginText.style.display = 'block';
            loginSpinner.style.display = 'none';
        }
    });

    function showAlert(alertDiv, type, message) {
        alertDiv.textContent = message;
        alertDiv.className = `alert alert-${type}`;
        alertDiv.style.display = 'block';

        // Auto-hide after 5 seconds
        setTimeout(() => {
            alertDiv.style.display = 'none';
        }, 5000);
    }

    // Focus on username field when page loads
    document.getElementById('username').focus();
</script>
</body>
</html>