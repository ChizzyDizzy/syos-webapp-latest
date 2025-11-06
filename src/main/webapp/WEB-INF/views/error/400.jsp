<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>400 Bad Request - SYOS POS</title>
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
    </style>
</head>
<body>
<div class="error-container">
    <div class="error-content">
        <div class="error-icon">🚫</div>
        <h1 class="error-title">400 Bad Request</h1>
        <p class="error-message">
            The server couldn't understand your request. Please check the information you provided and try again.
        </p>

        <div class="error-actions">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="btn btn-primary">
                🏠 Go to Dashboard
            </a>
            <button onclick="history.back()" class="btn btn-secondary">
                ↩️ Go Back
            </button>
            <a href="${pageContext.request.contextPath}/views/auth/login.jsp" class="btn btn-outline">
                🔐 Login Again
            </a>
        </div>

        <div class="error-details">
            <strong>Technical Details:</strong><br>
            • Invalid request syntax<br>
            • Malformed request message<br>
            • Deceptive request routing<br>
            • Size too large<br>
            • URI too long
        </div>

        <div style="margin-top: 20px; font-size: 0.8rem; color: #a0aec0;">
            Request ID: <%= System.currentTimeMillis() %><br>
            Timestamp: <%= new java.util.Date() %>
        </div>
    </div>
</div>

<script>
    // Log error for analytics
    console.error('400 Bad Request Error:', {
        url: window.location.href,
        referrer: document.referrer,
        userAgent: navigator.userAgent
    });
</script>
</body>
</html>