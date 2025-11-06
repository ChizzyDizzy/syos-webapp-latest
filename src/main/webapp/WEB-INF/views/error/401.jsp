<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>401 Unauthorized - SYOS POS</title>
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
            color: #dd6b20;
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
    </style>
</head>
<body>
<div class="error-container">
    <div class="error-content">
        <div class="error-icon">🔒</div>
        <h1 class="error-title">401 Unauthorized</h1>
        <p class="error-message">
            You need to be authenticated to access this resource. Please log in with valid credentials.
        </p>

        <div class="error-actions">
            <a href="${pageContext.request.contextPath}/views/auth/login.jsp" class="btn btn-primary">
                🔐 Login Now
            </a>
            <button onclick="history.back()" class="btn btn-secondary">
                ↩️ Go Back
            </button>
            <a href="${pageContext.request.contextPath}/" class="btn btn-outline">
                🏠 Home Page
            </a>
        </div>

        <div class="error-details">
            <strong>Possible Reasons:</strong><br>
            • Invalid or missing authentication token<br>
            • Session has expired<br>
            • Invalid credentials provided<br>
            • Access requires valid login
        </div>

        <div style="margin-top: 20px; font-size: 0.8rem; color: #a0aec0;">
            Request ID: <%= System.currentTimeMillis() %><br>
            Timestamp: <%= new java.util.Date() %>
        </div>
    </div>
</div>

<script>
    // Clear any invalid session data
    sessionStorage.removeItem('authToken');
    sessionStorage.removeItem('userRole');
    sessionStorage.removeItem('username');

    console.error('401 Unauthorized Error:', {
        url: window.location.href,
        authenticated: !!sessionStorage.getItem('authToken')
    });
</script>
</body>
</html>