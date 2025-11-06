<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>403 Forbidden - SYOS POS</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
    <style>
        .error-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .error-content {
            background: white;
            border-radius: 10px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 500px;
            width: 100%;
        }
        .error-icon {
            font-size: 4rem;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 2rem;
            color: #e53e3e;
            margin-bottom: 10px;
        }
        .error-message {
            color: #4a5568;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .error-actions {
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .error-details {
            margin-top: 20px;
            padding: 15px;
            background: #f7fafc;
            border-radius: 5px;
            text-align: left;
            font-size: 0.9rem;
            color: #718096;
        }
        .permission-list {
            list-style: none;
            padding: 0;
            margin: 10px 0;
        }
        .permission-list li {
            padding: 5px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .permission-list li:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
<div class="error-container">
    <div class="error-content">
        <div class="error-icon">🚫</div>
        <h1 class="error-title">403 Forbidden</h1>
        <p class="error-message">
            You don't have permission to access this resource. Please contact your administrator if you believe this is an error.
        </p>

        <div class="error-actions">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="btn btn-primary">
                🏠 Go to Dashboard
            </a>
            <button onclick="history.back()" class="btn btn-secondary">
                ↩️ Go Back
            </button>
            <a href="${pageContext.request.contextPath}/views/user/profile.jsp" class="btn btn-outline">
                👤 My Profile
            </a>
        </div>

        <div class="error-details">
            <strong>Access Requirements:</strong>
            <ul class="permission-list">
                <li>🔐 Valid user authentication</li>
                <li>👥 Appropriate user role</li>
                <li>📋 Required permissions</li>
                <li>✅ Account in active status</li>
            </ul>

            <strong>Your Current Role:</strong><br>
            <span id="current-role">Loading...</span>
        </div>

        <div style="margin-top: 20px; font-size: 0.8rem; color: #a0aec0;">
            Request ID: <%= System.currentTimeMillis() %><br>
            Timestamp: <%= new java.util.Date() %>
        </div>
    </div>
</div>

<script>
    // Display current user role if available
    const userRole = sessionStorage.getItem('userRole');
    document.getElementById('current-role').textContent = userRole ? userRole : 'Not authenticated';

    console.error('403 Forbidden Error:', {
        url: window.location.href,
        userRole: userRole,
        requiredRole: 'ADMIN/MANAGER' // This would come from server
    });
</script>
</body>
</html>