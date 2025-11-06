<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - Register User</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="container">
    <div class="login-container">
        <div class="login-header">
            <h1>👥 Register User</h1>
            <p class="subtitle">Create new user account</p>
        </div>

        <form id="register-form" class="login-form">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" class="form-control" required
                       placeholder="Enter username">
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" class="form-control" required
                       placeholder="Enter password">
            </div>

            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" class="form-control"
                       placeholder="Enter email (optional)">
            </div>

            <div class="form-group">
                <label for="role">Role</label>
                <select id="role" name="role" class="form-control" required>
                    <option value="">Select Role</option>
                    <option value="CASHIER">Cashier</option>
                    <option value="MANAGER">Manager</option>
                    <option value="ADMIN">Admin</option>
                </select>
            </div>

            <div class="form-group">
                <button type="submit" class="btn btn-primary btn-block">
                    <span id="register-text">Register User</span>
                    <div id="register-spinner" class="spinner" style="display: none;"></div>
                </button>
            </div>
        </form>

        <div id="register-alert" class="alert" style="display: none;"></div>

        <div class="login-footer">
            <a href="${pageContext.request.contextPath}/views/auth/login.jsp"
               class="btn btn-secondary btn-block">Back to Login</a>
        </div>
    </div>
</div>

<script>
    document.getElementById('register-form').addEventListener('submit', async function(e) {
        e.preventDefault();

        const formData = {
            username: document.getElementById('username').value,
            password: document.getElementById('password').value,
            email: document.getElementById('email').value,
            role: document.getElementById('role').value
        };

        const alertDiv = document.getElementById('register-alert');
        const registerText = document.getElementById('register-text');
        const registerSpinner = document.getElementById('register-spinner');

        // Show loading state
        registerText.style.display = 'none';
        registerSpinner.style.display = 'block';

        try {
            const authToken = sessionStorage.getItem('authToken');
            const response = await fetch('${pageContext.request.contextPath}/api/user/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${authToken}`
                },
                body: JSON.stringify(formData)
            });

            const data = await response.json();

            if (data.success) {
                showAlert(alertDiv, 'success', 'User registered successfully!');
                document.getElementById('register-form').reset();
            } else {
                showAlert(alertDiv, 'error', data.message || 'Registration failed');
            }
        } catch (error) {
            showAlert(alertDiv, 'error', 'Registration failed: ' + error.message);
        } finally {
            // Reset loading state
            registerText.style.display = 'block';
            registerSpinner.style.display = 'none';
        }
    });

    function showAlert(alertDiv, type, message) {
        alertDiv.textContent = message;
        alertDiv.className = `alert alert-${type}`;
        alertDiv.style.display = 'block';

        setTimeout(() => {
            alertDiv.style.display = 'none';
        }, 5000);
    }
</script>
</body>
</html>